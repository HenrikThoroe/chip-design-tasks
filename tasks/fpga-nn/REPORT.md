# Report

## Network

The network definition can be found under src/fpga_nn/nn/net.py.
The network consists of:

- Conv (Kernel: 5x5, In. Features: 1, Out. Features: 12, Weight Bit Width: 2)
- Max Pool (Kernel: 2x2)
- Conv (Kernel: 5x5, In. Features: 12, Out. Features: 16, Weight Bit Width: 2)
- Max Pool (Kernel: 2x2)
- Linear (256x10, Weight Bit Width: 2)
- LogSoftmax (Software Only)

The input is quantized to 4 bit.
The accuracy on the training dataset is 96.4%.

## Scripts / Sources

The project consists of the following files under `src/fpga_nn`:

- `cmd`
  - The CLI interface for user interactions
  - `train`: Starts the PyTorch / Brevitas training and exports the model as ONNX
  - `synth`: Calls FINN for the exported ONNX
- `nn`
  - Logic and network code
  - `dataset`: Loader for the MNIST dataset imported from torchvision
  - `net`: The definition for the neural network using PyTorch and Brevitas layers
  - `driver`: A driver class for running training and testing on the network, as well as exporting to `.pth` and `.onnx` formats.

The folding config and dataflow config can be found at the root level.

## Build Reports

FINN generated reports can be found under `dist/synth`.
Key takeaways are:

- RTL Simulation Performance
  - Throughput: 15890 Images/s
  - Latency: 6293 cycles
  - Frequency: 100 MHz
- Estimated Resource Requirements:
  - BRAM 36K: 6
  - BRAM 18K: 2
  - LUTS: 11964
  - FF: 16671

## Artifacts

- `dist/model.onnx`
  - The quantized ONNX file
- `cache/checkpoint.pth`
  - The checkpoint file, that can be used to restore the network state for training / export / testing.
- `dist/synth/**/*`
  - The generated build artifacts by FINN.
  - Inlcudes the bitstream, hardware handoff, estimate and sim. reports and auto generated driver for Pynq deployment
