import os
from pathlib import Path
import subprocess
import click
import shutil


@click.command()
@click.option(
    "--xilinx-path", "-x", type=str, required=True, help="Path to Xilinx installation"
)
@click.option(
    "--xilinx-version",
    "-v",
    type=str,
    required=True,
    help="Xilinx version, e.g., 2024.1",
)
@click.option(
    "--finn-path", "-f", type=str, required=True, help="Path to FINN repository"
)
def synth(xilinx_path: str, xilinx_version: str, finn_path: str):
    build_dir = Path.cwd() / "build"
    xilinx_env = os.environ.copy()
    xilinx_env["FINN_XILINX_PATH"] = xilinx_path
    xilinx_env["FINN_XILINX_VERSION"] = xilinx_version
    xilinx_env["FINN_HOST_BUILD_DIR"] = build_dir.absolute().as_posix()
    cmd = f"./run-docker.sh build_dataflow {build_dir.resolve().as_posix()}"

    shutil.copy(Path.cwd() / "dist" / "model.onnx", build_dir / "model.onnx")
    shutil.copy(
        Path.cwd() / "dataflow_build_config.json",
        build_dir / "dataflow_build_config.json",
    )
    shutil.copy(
        Path.cwd() / "folding_config.json",
        build_dir / "folding_config.json",
    )

    subprocess.run(cmd, shell=True, env=xilinx_env, cwd=Path(finn_path))
    shutil.copytree(
        build_dir / "out",
        Path.cwd() / "dist" / "synth",
        dirs_exist_ok=True,
    )
