import click
from fpga_nn.cmd.synth import synth
from fpga_nn.cmd.train import train


@click.group()
def cli():
    pass


cli.add_command(train)
cli.add_command(synth)
