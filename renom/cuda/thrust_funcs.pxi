#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
関数命名規則
関数名: cu〜    (python側から呼ばれる関数)
        
引数名: gpu_value
"""
import numpy as np
from libc.stdint cimport uintptr_t


def cunegate(input, result):
    cdef VALUE_TYPE * first = <VALUE_TYPE * > < uintptr_t > input._ptr
    cdef VALUE_TYPE * last = first + <size_t > input.size
    cdef VALUE_TYPE * output = <VALUE_TYPE * > < uintptr_t > result._ptr
    thrust_negate(first, last, output)


def curelu_foward(gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_relu_forward(ptr1, ptr2, size)


def curelu_backard(gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_relu_backward(ptr1, ptr2, size)


def culeaky_leru_forward(s, gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_leaky_relu_forward(< VALUE_TYPE > s, ptr1, ptr2, size);


def culeaky_leru_backward(s, gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_leaky_relu_backward(< VALUE_TYPE > s, ptr1, ptr2, size);


def cueru_forward(s, gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_elu_forward(< VALUE_TYPE > s, ptr1, ptr2, size);


def cueru_backward(s, gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_elu_backward(< VALUE_TYPE > s, ptr1, ptr2, size);


def cusigmoid(gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_sigmoid(ptr1, ptr2, size)


def cutanh(gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_tanh(ptr1, ptr2, size)


cdef basic_operation(Operation op, gpu_value1, gpu_value2, gpu_value3):
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2
    cdef VALUE_TYPE * ptr3 = <VALUE_TYPE * > < uintptr_t > gpu_value3._ptr
    cdef int elem_size_a = gpu_value1.size
    cdef int elem_size_b
    if hasattr(gpu_value2, "_ptr"):
        ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
        value = 0
        elem_size_b = gpu_value2.size
    else:
        ptr2 = <VALUE_TYPE * >0
        value = gpu_value2
        elem_size_b = 1
    thrust_operation(op, < VALUE_TYPE > value, elem_size_a, ptr1, elem_size_b, ptr2, ptr3)


def cumul(gpu_value1, gpu_value2, gpu_value3):
    basic_operation(Operation.MUL, gpu_value1, gpu_value2, gpu_value3)


def cuadd(gpu_value1, gpu_value2, gpu_value3):
    basic_operation(Operation.ADD, gpu_value1, gpu_value2, gpu_value3)


def cusub(gpu_value1, gpu_value2, gpu_value3):
    basic_operation(Operation.SUB, gpu_value1, gpu_value2, gpu_value3)


def cudiv(gpu_value1, gpu_value2, gpu_value3):
    basic_operation(Operation.DIV, gpu_value1, gpu_value2, gpu_value3)


def curdiv(gpu_value1, gpu_value2, gpu_value3):
    basic_operation(Operation.RDIV, gpu_value1, gpu_value2, gpu_value3)


def cupow(gpu_value1, gpu_value2, gpu_value3):
    basic_operation(Operation.POW, gpu_value1, gpu_value2, gpu_value3)


def curpow(gpu_value1, gpu_value2, gpu_value3):
    basic_operation(Operation.RPOW, gpu_value1, gpu_value2, gpu_value3)


def cufill(value, gpu_value):
    cdef int size = <int > gpu_value.size
    cdef VALUE_TYPE v = <VALUE_TYPE > value
    cdef VALUE_TYPE * ptr = <VALUE_TYPE * > < uintptr_t > gpu_value._ptr
    thrust_fill(v, ptr, size)


def culoge(gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_loge(ptr1, ptr2, size)


def cuexp(gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_exp(ptr1, ptr2, size)


def cusqrt(gpu_value1, gpu_value2):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_sqrt(ptr1, ptr2, size)


def cucross_entropy(gpu_value1, gpu_value2, gpu_value3):
    cdef int size = <int > gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    cdef VALUE_TYPE * ptr3 = <VALUE_TYPE * > < uintptr_t > gpu_value3._ptr
    thrust_cross_entropy(ptr1, ptr2, ptr3, size)


def cubroadcast(gpu_value1, gpu_value2):
    cdef int size_1 = <int > gpu_value1.size
    cdef int size_2 = <int > gpu_value2.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_broad_cast(size_1, ptr1, size_2, ptr2)


def cuabs_forward(gpu_value1, gpu_value2):
    cdef int size = gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_abs_forward(ptr1, ptr2, size)


def cuabs_backward(gpu_value1, gpu_value2):
    cdef int size = gpu_value1.size
    cdef VALUE_TYPE * ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = <VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    thrust_abs_backward(ptr1, ptr2, size)


def cusum(gpu_value1, gpu_value2=None, axis=None):
    cdef int size = gpu_value1.size
    cdef VALUE_TYPE * ptr1
    cdef VALUE_TYPE * ptr2
    if axis is None:
        ptr1 = <VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
        return thrust_all_reduce(ptr1, size)
    else:
        axis_size = gpu_value1.shape[axis]

        if axis == 1:
            strides = 1
        elif axis == 0:
            if len(gpu_value1.shape) == 1:
                strides = 1
            else:
                strides = gpu_value1.shape[1]
        else:
            strides = np.prod(gpu_value1.shape[:axis])

        step = 1 if axis != 1 else gpu_value1.shape[1]
        thrust_strided_reduce( < VALUE_TYPE*> < uintptr_t > gpu_value1._ptr,
                              < VALUE_TYPE * > < uintptr_t > gpu_value2._ptr,
                              strides, axis_size, step, size)


def cumin(value, gpu_value1, gpu_value2=None):
    cdef int size = gpu_value1.size
    cdef VALUE_TYPE * ptr1 = < VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = < VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    cdef VALUE_TYPE v = <VALUE_TYPE > value
    thrust_min(v, ptr1, ptr2, size)


def cumax(value, gpu_value1, gpu_value2=None):
    cdef int size = gpu_value1.size
    cdef VALUE_TYPE * ptr1 = < VALUE_TYPE * > < uintptr_t > gpu_value1._ptr
    cdef VALUE_TYPE * ptr2 = < VALUE_TYPE * > < uintptr_t > gpu_value2._ptr
    cdef VALUE_TYPE v = <VALUE_TYPE > value
    thrust_max(v, ptr1, ptr2, size)


def culstm_forward_activate(u):
    cdef int N = u.shape[0]
    cdef int M = u.shape[1]

    cdef VALUE_TYPE * ptr_u = < VALUE_TYPE * > < uintptr_t > u._ptr
    thrust_forward_lstm_activate(N, M, ptr_u)


def culstm_forward(u, s, ps, z):
    cdef int N = u.shape[0]
    cdef int M = u.shape[1]

    cdef VALUE_TYPE * ptr_u = < VALUE_TYPE * > < uintptr_t > u._ptr
    cdef VALUE_TYPE * ptr_s = < VALUE_TYPE * > < uintptr_t > s._ptr
    cdef VALUE_TYPE * ptr_ps = < VALUE_TYPE * > < uintptr_t > ps._ptr
    cdef VALUE_TYPE * ptr_z = < VALUE_TYPE * > < uintptr_t > z._ptr
    thrust_forward_lstm(N, M, ptr_u, ptr_s, ptr_ps, ptr_z)


def culstm_backward(u, du, s, ps, e, pgf, dou, dou_n):
    cdef int N = u.shape[0]
    cdef int M = u.shape[1]
    cdef VALUE_TYPE * ptr_u = < VALUE_TYPE * > < uintptr_t > u._ptr
    cdef VALUE_TYPE * ptr_du = < VALUE_TYPE * > < uintptr_t > du._ptr
    cdef VALUE_TYPE * ptr_s = < VALUE_TYPE * > < uintptr_t > s._ptr
    cdef VALUE_TYPE * ptr_ps = < VALUE_TYPE * > < uintptr_t > ps._ptr
    cdef VALUE_TYPE * ptr_e = < VALUE_TYPE * > < uintptr_t > e._ptr
    cdef VALUE_TYPE * ptr_pgf = < VALUE_TYPE * > < uintptr_t > pgf._ptr
    cdef VALUE_TYPE * ptr_dou = < VALUE_TYPE * > < uintptr_t > dou._ptr
    cdef VALUE_TYPE * ptr_dou_n = < VALUE_TYPE * > < uintptr_t > dou_n._ptr
    thrust_backward_lstm(N, M, ptr_u, ptr_du, ptr_s, ptr_ps, ptr_e, ptr_pgf, ptr_dou, ptr_dou_n)
