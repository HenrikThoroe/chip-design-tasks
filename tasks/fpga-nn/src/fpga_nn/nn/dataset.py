from pathlib import Path
from typing import Tuple
from torchvision.datasets import MNIST
from torchvision import transforms


def load_dataset(data_store: Path) -> Tuple[MNIST, MNIST]:
    transform = transforms.Compose(
        [
            transforms.Resize((28, 28)),
            transforms.Grayscale(),
            transforms.ToTensor(),
            transforms.Normalize((0,), (1,)),
        ]
    )

    train_dataset = MNIST(
        root=data_store.resolve(),
        train=True,
        download=True,
        transform=transform,
    )
    test_dataset = MNIST(
        root=data_store.resolve(),
        train=False,
        download=True,
        transform=transform,
    )

    return train_dataset, test_dataset
