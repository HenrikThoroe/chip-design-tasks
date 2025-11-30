from pathlib import Path
import torch
from torchvision.datasets import MNIST
from torchvision import transforms
from torch.utils.data import DataLoader
from rich.progress import track
from torch import Tensor, no_grad, max
from torch.nn.functional import nll_loss
from torch.nn import Module
from brevitas.export import export_qonnx


class NetworkDriver:
    def __init__(
        self,
        network: Module,
        batch_size: int,
        data_store: Path,
        cache: Path,
        dist: Path,
    ) -> None:
        transform = transforms.Compose(
            [
                transforms.Resize((28, 28)),
                transforms.Grayscale(),
                transforms.ToTensor(),
                transforms.Normalize((0,), (1,)),
            ]
        )

        self._device = (
            torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
        )
        self._net = network.to(self._device)
        self._cache_path = cache
        self._dist = dist
        self._optimizer = torch.optim.Adadelta(self._net.parameters(), lr=0.1)
        self._train_dataset = MNIST(
            root=data_store.resolve(),
            train=True,
            download=True,
            transform=transform,
        )
        self._test_dataset = MNIST(
            root=data_store.resolve(),
            train=False,
            download=True,
            transform=transform,
        )
        self._train_dl = DataLoader(
            self._train_dataset,
            batch_size=batch_size,
            shuffle=True,
            drop_last=True,
        )
        self._test_dl = DataLoader(
            self._test_dataset,
            batch_size=batch_size,
            shuffle=False,
            drop_last=False,
        )

    def train(self, label: str):
        for data, targets in track(iter(self._train_dl), label):
            data: Tensor = data.detach().to(self._device)
            targets: Tensor = targets.to(self._device)
            self._net.train()
            self._optimizer.zero_grad()
            outputs: Tensor = self._net(data)
            loss: Tensor = nll_loss(outputs, targets)
            loss.backward()
            self._optimizer.step()

    def test(self, label: str) -> float:
        correct = 0
        total = 0
        self._net.eval()
        with no_grad():
            for data, targets in track(iter(self._test_dl), label):
                data: Tensor = data.detach().to(self._device)
                targets: Tensor = targets.to(self._device)
                outputs: Tensor = self._net(data)
                _, predicted = max(outputs.data, 1)
                total += targets.size(0)
                correct += (predicted == targets).sum().item()
        accuracy = 100 * correct / total
        return accuracy

    def export(self):
        export_path = self._dist / "model.onnx"
        export_path.parent.mkdir(parents=True, exist_ok=True)
        export_qonnx(
            self._net,
            torch.zeros(size=(1, 1, 28, 28)),
            export_path=export_path,
            opset_version=13,
        )

    def save_checkpoint(self) -> None:
        if not self._cache_path:
            return

        if not self._cache_path.exists():
            self._cache_path.mkdir(parents=True, exist_ok=True)

        torch.save(self._net.state_dict(), self._cache_path / "checkpoint.pth")

    def load_checkpoint(self) -> bool:
        if not self._cache_path:
            return False

        exists = (self._cache_path / "checkpoint.pth").exists()

        if exists:
            self._net.load_state_dict(torch.load(self._cache_path / "checkpoint.pth"))

        return exists
