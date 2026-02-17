import os
import shutil
import time
import torch
import onnx

import finn.builder.build_dataflow as build
import finn.builder.build_dataflow_config as build_cfg
from finn.util.pytorch import ToTensor
from qonnx.transformation.merge_onnx_models import MergeONNXModels
from qonnx.core.modelwrapper import ModelWrapper
from qonnx.core.datatype import DataType
from qonnx.transformation.insert_topk import InsertTopK

from finn.transformation.streamline.reorder import MoveScalarLinearPastInvariants
import finn.transformation.streamline.absorb as absorb
from finn.transformation.streamline import Streamline
from qonnx.transformation.bipolar_to_xnor import ConvertBipolarMatMulToXnorPopcount
from finn.transformation.streamline.round_thresholds import RoundAndClipThresholds
from qonnx.transformation.infer_data_layouts import InferDataLayouts
from qonnx.transformation.general import RemoveUnusedTensors
from finn.transformation.qonnx.convert_qonnx_to_finn import ConvertQONNXtoFINN
from qonnx.transformation.general import GiveReadableTensorNames, GiveUniqueNodeNames, RemoveStaticGraphInputs
from qonnx.transformation.infer_shapes import InferShapes
from qonnx.transformation.infer_datatypes import InferDataTypes
from qonnx.transformation.fold_constants import FoldConstants
from qonnx.custom_op.registry import getCustomOp
from finn.util.basic import pynq_part_map
from finn.transformation.fpgadataflow.specialize_layers import SpecializeLayers
import finn.transformation.fpgadataflow.convert_to_hw_layers as to_hw

import finn.custom_op.fpgadataflow.matrixvectoractivation as matrixvectoractivation
import finn.custom_op.fpgadataflow.thresholding as thresholding

from brevitas.export import export_qonnx
from qonnx.util.cleanup import cleanup as qonnx_cleanup

# trained model architecture
# import your neural network model architecture
from FC import FC

# your working folder
build_dir = os.environ["FINN_ROOT"] + "" #e.g., "/notebooks/Lab_nn"


print(build_dir)

## set quantization parameters

input_w = 28
input_h = 28

model = FC(
    weight_bit_width=2,
    act_bit_width=3,
    in_bit_width=8,
    in_channels=1,
    out_features=[64,64,64],
    num_classes=10
)

# load your trained model 
model_path = build_dir + f"/models/custom_nn.pth"

# Load the model on CPU
state_dict = torch.load(model_path, map_location=torch.device('cpu'))
model.load_state_dict(state_dict)

for name, param in model.state_dict().items():
    print(f"Layer: {name}")
    print(param)
    print()



model.eval()
export_onnx_path = build_dir+ f"/custom_nn.onnx"
export_qonnx(model, torch.randn(1, 1, input_w, input_h), build_dir+ f"/custom_nn.onnx"); # semicolon added to suppress log
qonnx_cleanup(export_onnx_path, out_file=export_onnx_path)


def custom_step_add_pre_proc(model: ModelWrapper, cfg: build.DataflowBuildConfig):
    ishape = model.get_tensor_shape(model.graph.input[0].name)
    # preprocessing: torchvision's ToTensor divides uint8 inputs by 255
    preproc = ToTensor()
    export_qonnx(preproc, torch.randn(ishape), "preproc.onnx", opset_version=11)
    preproc_model = ModelWrapper("preproc.onnx")
    # set input finn datatype to UINT8
    preproc_model.set_tensor_datatype(preproc_model.graph.input[0].name, DataType["UINT8"])
    # merge pre-processing onnx model with cnv model (passed as input argument)
    model = model.transform(MergeONNXModels(preproc_model))

    #change output datatype from uint8 to bipolar
    output_name = model.graph.output[0].name  
    model.set_tensor_datatype(output_name, DataType["UINT8"])
    return model

def custom_step_add_post_proc(model: ModelWrapper, cfg: build.DataflowBuildConfig):
    model = model.transform(InsertTopK(k=1))
    return model

def custom_step_qonnx_to_finn(model: ModelWrapper, cfg: build.DataflowBuildConfig):
    model = model.transform(ConvertQONNXtoFINN())
    return model

def custom_step_tidy_up(model: ModelWrapper, cfg: build.DataflowBuildConfig):
    model = model.transform(InferShapes())
    model = model.transform(FoldConstants())
    model = model.transform(GiveUniqueNodeNames())
    model = model.transform(GiveReadableTensorNames())
    model = model.transform(InferDataTypes())
    model = model.transform(RemoveStaticGraphInputs())
    return model

def custom_step_streamline(model: ModelWrapper, cfg: build.DataflowBuildConfig):
    model = model.transform(MoveScalarLinearPastInvariants())
    # streamline
    model = model.transform(Streamline())
    model = model.transform(ConvertBipolarMatMulToXnorPopcount())
    model = model.transform(absorb.AbsorbAddIntoMultiThreshold())
    model = model.transform(absorb.AbsorbMulIntoMultiThreshold())
    # absorb final add-mul nodes into TopK
    model = model.transform(absorb.AbsorbScalarMulAddIntoTopK())
    model = model.transform(RoundAndClipThresholds())
    # bit of tidy-up
    model = model.transform(InferDataLayouts())
    model = model.transform(RemoveUnusedTensors())
    return model

def custom_step_convert_to_hw(model: ModelWrapper, cfg: build.DataflowBuildConfig):
    model = model.transform(to_hw.InferBinaryMatrixVectorActivation())
    model = model.transform(to_hw.InferQuantizedMatrixVectorActivation())
    model = model.transfrom(to_hw.InferLabelSelectLayer())
    model = model.transform(to_hw.InferThresholdingLayer())
    return model

def custom_step_specialize_layers(model: ModelWrapper, cfg: build.DataflowBuildConfig):
    thresh_node = model.get_nodes_by_op_type("Thresholding")[0]
    thresh_node_inst = getCustomOp(thresh_node)
    thresh_node_inst.set_nodeattr("preferred_impl_style", "hls")
    pynq_board = "Pynq-Z2"
    fpga_part = pynq_part_map[pynq_board]
    model = model.transform(SpecializeLayers(fpga_part))
    return model



model_file = build_dir+ f"/custom_nn.onnx"
output_dir = build_dir + "/output_bitfile"

#Delete previous run results if exist
if os.path.exists(output_dir):
    shutil.rmtree(output_dir)
    print("Previous run results deleted!")

build_steps = [
    custom_step_qonnx_to_finn,
    custom_step_add_pre_proc,
    custom_step_add_post_proc,
    custom_step_tidy_up,
    custom_step_streamline,
    "step_convert_to_hw",
    "step_create_dataflow_partition",
    custom_step_specialize_layers,
    "step_target_fps_parallelization", #auto generated folding configuration as starting point
    "step_apply_folding_config",
    "step_generate_estimate_reports",
    "step_hw_codegen",
    "step_hw_ipgen",
    "step_set_fifo_depths",
    "step_create_stitched_ip",
    "step_measure_rtlsim_performance",
    "step_out_of_context_synthesis",
    "step_synthesize_bitfile",
    "step_make_pynq_driver",
    "step_deployment_package",
]

cfg_build = build.DataflowBuildConfig(
    output_dir                    = output_dir,
    mvau_wwidth_max               = 10000,
    target_fps                    = 1000000,
    synth_clk_period_ns           = 10,
    specialize_layers_config_file = "specialize_layers_config.json",
    folding_config_file           = "folding_config.json",
    board                         = "Pynq-Z2",
    shell_flow_type               = build_cfg.ShellFlowType.VIVADO_ZYNQ,
    steps                         = build_steps,
    default_swg_exception         = True,
    auto_fifo_depths              = True,
    generate_outputs=[
        build_cfg.DataflowOutputType.ESTIMATE_REPORTS,
        build_cfg.DataflowOutputType.STITCHED_IP,
        build_cfg.DataflowOutputType.RTLSIM_PERFORMANCE,
        build_cfg.DataflowOutputType.OOC_SYNTH,
        build_cfg.DataflowOutputType.BITFILE,
        build_cfg.DataflowOutputType.PYNQ_DRIVER,
        build_cfg.DataflowOutputType.DEPLOYMENT_PACKAGE,
    ],
)

start = time.time()
build.build_dataflow_cfg(model_file, cfg_build)
end   = time.time()

print(f"Finn accelerator generation time {end - start}s")
