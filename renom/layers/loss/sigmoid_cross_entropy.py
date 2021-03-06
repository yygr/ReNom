#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function, division
import numpy as np
from renom.core import Node, get_gpu, to_value
from renom.cuda import cuda as cu


class sigmoid_cross_entropy(Node):

    def __new__(cls, lhs, rhs):
        assert rhs.ndim > 1, "Input arrays must have no less than 2 dimension."
        return cls.calc_value(lhs, rhs)

    @classmethod
    def _oper_cpu(cls, lhs, rhs):
        N = len(lhs)
        z = 1. / (1. + np.exp(to_value(-lhs)))
        loss = -np.sum(to_value(rhs) * np.log(z + 1e-8) +
                       to_value(1 - rhs) * np.log(1 - z + 1e-8)) / N
        ret = cls._create_node(loss)
        ret.attrs._z = z
        ret.attrs._lhs = lhs
        ret.attrs._rhs = rhs
        return ret

    @classmethod
    def _oper_gpu(cls, lhs, rhs):
        N = len(lhs)
        z = get_gpu(lhs).empty_like_me()
        tmp1 = get_gpu(lhs).empty_like_me()
        tmp2 = get_gpu(lhs).empty_like_me()
        cu.cusigmoid(get_gpu(lhs), z)
        cu.cucross_entropy(get_gpu(z), get_gpu(rhs), tmp1)
        cu.cucross_entropy(get_gpu(-z + 1.), get_gpu(-rhs + 1.), tmp2)
        loss = cu.cusum(-(tmp1 + tmp2)) / N
        ret = cls._create_node(loss)
        ret.attrs._z = z
        ret.attrs._lhs = lhs
        ret.attrs._rhs = rhs
        return ret

    def _backward_cpu(self, context, dy):
        if isinstance(self.attrs._lhs, Node):
            sub = self.attrs._z - self.attrs._rhs
            N = len(self.attrs._z)
            self.attrs._lhs._update_diff(context, sub * dy / N)

    def _backward_gpu(self, context, dy):
        if isinstance(self.attrs._lhs, Node):
            N = len(self.attrs._lhs)
            sub = get_gpu(self.attrs._z) - get_gpu(self.attrs._rhs)
            self.attrs._lhs._update_diff(context, sub * get_gpu(dy) / N)


class SigmoidCrossEntropy:
    """This function evaluates the loss between target ``y`` and output
    of sigmoid activation ``z`` using cross entropy.

    .. math::
        z_{nk} &= \\frac{1}{1 + \exp(-x_{nk})} \\\\
        E(x) &= -\\frac{1}{N}\sum_{n}^{N}\sum_{k}^{K}y_{nk}\log(z_{nk})+(1-y_{nk})\log(1-z_{nk})

    Args:
        x (ndarray,Node): Input array.
        y (ndarray,Node): Target array.

    Raises:
        AssertionError: An assertion error will be raised if the given tensor dimension is less than 2.

    """

    def __call__(self, lhs, rhs):
        return sigmoid_cross_entropy(lhs, rhs)
