#!/usr/bin/env python
# encoding: utf-8


import numpy as np
from renom.layers.function.utils import col2im, transpose_out_size, im2col, tuplize
from renom.core import Node, Variable, to_value, GPUValue, get_gpu, precision
from .parameterized import Parametrized
from renom.utility.initializer import GlorotNormal
from renom.cuda import cuda as cu


class deconv2d(Node):

    def __new__(cls, x, w, b, filter=3, stride=1, padding=0):
        filter, stride, padding = (tuplize(x) for x in (filter, stride, padding))
        in_shape = x.shape[1:]
        out_shape = [w.shape[1], ]
        out_shape.extend(transpose_out_size(in_shape[1:], filter, stride, padding))
        return cls.calc_value(x, w, b, in_shape, out_shape, filter, stride, padding)

    @classmethod
    def _oper_cpu(cls, x, w, b, in_shape, out_shape, kernel, stride, padding):

        z = np.tensordot(w, x, (0, 1))
        z = np.rollaxis(z, 3)
        z = col2im(z, out_shape[1:], stride, padding) + b
        ret = cls._create_node(z)
        ret.attrs._x = x
        ret.attrs._w = w
        ret.attrs._b = b
        ret.attrs._in_shape = in_shape
        ret.attrs._kernel = kernel
        ret.attrs._stride = stride
        ret.attrs._padding = padding
        return ret

    @classmethod
    def _oper_gpu(cls, x, w, b, in_shape, out_shape, kernel, stride, padding):
        conv_desc = cu.createConvplutionDescriptor(padding, stride, precision)
        filter_desc = cu.createFilterDescriptor(w.shape, precision)
        N = x.shape[0]
        # TODO: dirty code
        z = GPUValue(shape=tuple([N, ] + list(out_shape)))
        with cu.cudnn_handler() as handle:
            cu.cuConvolutionBackwardData(handle, conv_desc, filter_desc, w, x, z)
            cu.cuadd(get_gpu(z), get_gpu(b), get_gpu(z))

        ret = cls._create_node(z)
        ret.attrs._conv_desc = conv_desc
        ret.attrs._filter_desc = filter_desc
        ret.attrs._x = x
        ret.attrs._w = w
        ret.attrs._b = b
        return ret

    def _backward_cpu(self, context, dy):

        col = im2col(dy, self.attrs._in_shape[1:], self.attrs._kernel,
                     self.attrs._stride, self.attrs._padding)

        if isinstance(self.attrs._x, Node):
            dx = np.tensordot(col, self.attrs._w, ([1, 2, 3], [1, 2, 3]))
            dx = np.rollaxis(dx, 3, 1)
            self.attrs._x._update_diff(context, dx)

        if isinstance(self.attrs._w, Node):
            self.attrs._w._update_diff(context, np.tensordot(
                self.attrs._x, col, ([0, 2, 3], [0, 4, 5])))

        if isinstance(self.attrs._b, Node):
            self.attrs._b._update_diff(context, np.sum(dy, (0, 2, 3), keepdims=True))

    def _backward_gpu(self, context, dy):
        dw, db, dx = (get_gpu(g).empty_like_me()
                      for g in (self.attrs._w, self.attrs._b, self.attrs._x))

        with cu.cudnn_handler() as handle:
            cu.cuConvolutionForward(handle, self.attrs._conv_desc,
                                    self.attrs._filter_desc, dy, self.attrs._w, dx)
            cu.cuConvolutionBackwardFilter(handle, self.attrs._conv_desc,
                                           self.attrs._filter_desc, dy, self.attrs._x, dw)
            cu.cuConvolutionBackwardBias(handle, dy, db)

        if isinstance(self.attrs._x, Node):
            self.attrs._x._update_diff(context, dx)

        if isinstance(self.attrs._w, Node):
            self.attrs._w._update_diff(context, dw)

        if isinstance(self.attrs._b, Node):
            self.attrs._b._update_diff(context, db)


class Deconv2d(Parametrized):
    '''2d convolution function.

    This class creates a convolution filter to be convolved with
    the input tensor.
    The instance of this class only accepts and outputs 4d tensors.

    At instantiation, in the case of int input, filter, padding, and stride, the shape will be symmetric.

    Args:
        channel (int): The dimensionality of the output.
        filter (tuple,int): Filter size to witch used as convolution kernel.
        padding (tuple,int): Pad around image by 0 according to this size.
        stride (tuple,int): Specifying the strides of the convolution.
        input_size (tuple): Input unit size. This must be a tuple like (Channel, Height, Width).

    Example:
        >>> import numpy as np
        >>> import renom as rm
        >>> n, c, h, w = (10, 3, 32, 32)
        >>> x = np.random.rand(n, c, h, w)
        >>> x.shape
        (10, 3, 32, 32)
        >>> layer = rm.Deconv2d(channel=32)
        >>> z = layer(x)
        >>> z.shape
        (10, 32, 34, 34)

    '''

    def __init__(self, channel=1, filter=3, padding=0, stride=1, input_size=None, initializer=GlorotNormal()):
        self._padding, self._stride, self._kernel = (tuplize(x) for x in (padding, stride, filter))
        self._channel = channel
        self._initializer = initializer
        super(Deconv2d, self).__init__(input_size)

    def weight_initiallize(self, input_size):
        size_f = (input_size[0], self._channel,
                  self._kernel[0], self._kernel[1])
        self.params = {"w": Variable(self._initializer(size_f), auto_update=True),
                       "b": Variable(np.zeros((1, self._channel, 1, 1), dtype=precision), auto_update=True)}

    def forward(self, x):
        return deconv2d(x, self.params["w"], self.params["b"],
                        self._kernel, self._stride, self._padding)
