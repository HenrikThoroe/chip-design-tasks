# Neural Network Inference on FPGA - Project Report

## 1. Neural Network Model Architecture
The implemented model is a Quantized Multi-Layer Perceptron (MLP) designed for MNIST classification. The architecture details are as follows:
- **Input Layer**: 784 neurons (28x28 flattened image), 8-bit quantization.
- **Hidden Layers**: 3 layers with 64 neurons each.
  - Activation: RoHS Quantized ReLU (or similar via CommonActQuant), 8-bit.
  - Weights: Quantized (CommonWeightQuant), 8-bit.
  - Normalization: Batch Normalization after each linear layer.
  - Dropout: 0.2 probability.
- **Output Layer**: 10 neurons (for digit classes 0-9), 8-bit quantization.

The model was defined using Brevitas `QuantLinear` and trained using PyTorch. The best model state is saved in `custom_nn.pth`.

## 2. Configuration for FINN Flow
To optimize the hardware implementation on FPGA, the following configurations were applied:

### Folding Configuration (`folding_config.json`)
The parallelism was tuned to balance resource usage and throughput.
- **MVAU_hls_0** (Input Layer): PE=4, SIMD=49. This allows processing 4 output channels in parallel and 49 input elements per cycle.
- **MVAU_hls_1 & 2** (Hidden Layers): PE=4, SIMD=16.
- **MVAU_hls_3** (Output Layer): PE=2, SIMD=16.

### Layer Specialization (`specialize_layers_config.json`)
All layers were configured to use HLS (`preferred_impl_style: "hls"`) to ensure compatibility and leverage Vivado HLS optimizations.



## Implementation Locations
The following list details where specific parts of the project are implemented within the workspace:

- **Model Definition & Training**:
  - `custom_nn.py`: Contains the `QuantizedMLP` class definition using Brevitas layers (`QuantLinear`, `QuantReLU`), the training loop, and the model saving logic.
  - `custom_nn.pth`: The saved PyTorch model state dict after training.

- **FINN Flow Configuration**:
  - `folding_config.json`: Defines the hardware parallelization (PE & SIMD) for each layer to optimize throughput vs. resource usage.
  - `specialize_layers_config.json`: Specifies the implementation style (set to "hls" for all layers) for the Vivado HLS synthesis.

- **Hardware Synthesis Outputs**:
  - `finn_flow/output_bitfile/report/rtlsim_performance.json`: The generated performance report containing cycle counts, resource utilization (LUT, DSP, BRAM), and power estimates.
  - `finn_flow/output_bitfile/deploy/`: The final deployment folder containing the generated bitfile (`yourfile.bit`) and the driver scripts.

- **Deployment & Validation Scripts**:
  - `finn_flow/output_bitfile/deploy/driver.py`: Script to load the bitfile and run inference on a single input (`input.npy`).
  - `finn_flow/output_bitfile/deploy/validate.py`: Script to validate the accuracy of the hardware implementation against the full MNIST test dataset.

## Source Files
- `custom_nn.py`: Training script with model definition and test loop.
- `folding_config.json` & `specialize_layers_config.json`: FINN configuration files.
- `finn_flow/output_bitfile/deploy/`: Contains the bitfile and Python drivers for PYNQ.
