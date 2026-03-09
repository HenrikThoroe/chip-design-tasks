from torch import nn
from brevitas.nn import QuantConv2d, QuantLinear, QuantIdentity, QuantReLU


def build_net():
    return nn.Sequential(
        QuantIdentity(bit_width=4),
        QuantConv2d(
            1,
            12,
            5,
            bias=False,
            weight_bit_width=2,
        ),
        QuantReLU(bit_width=4),
        nn.MaxPool2d(2),
        QuantConv2d(
            12,
            16,
            5,
            bias=False,
            weight_bit_width=2,
        ),
        QuantReLU(bit_width=4),
        nn.MaxPool2d(2),
        nn.Flatten(),
        QuantLinear(
            16 * 4 * 4,
            10,
            bias=False,
            weight_bit_width=2,
        ),
        nn.LogSoftmax(dim=1),
    )
