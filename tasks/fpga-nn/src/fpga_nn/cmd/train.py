import click
from pathlib import Path
from fpga_nn.nn.driver import NetworkDriver
from fpga_nn.nn.net import build_net
from rich.console import Console


@click.command()
@click.option("--batch", "-b", type=int, default=64, help="Batch size for training.")
@click.option("--epochs", "-e", type=int, default=10, help="Number of training epochs.")
def train(batch: int, epochs: int):
    console = Console()
    model = build_net()
    driver = NetworkDriver(
        model,
        batch_size=batch,
        data_store=Path.cwd() / "data",
        cache=Path.cwd() / "cache",
        dist=Path.cwd() / "dist",
    )

    driver.load_checkpoint()

    for i in range(epochs):
        driver.train(f"Training epoch {i + 1}/{epochs}")
        acc = driver.test(f"Testing epoch {i + 1}/{epochs}")
        console.print(f"Accuracy after epoch {i + 1}/{epochs}: {acc:.2f}%")
        driver.save_checkpoint()

    driver.export()
    console.print("Network successfully exported!", style="bold green")
