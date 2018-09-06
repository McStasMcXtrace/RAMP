import numpy as np
import pyopencl.array as clarr

from abc import ABCMeta, abstractmethod

class SPrim():
    __metaclass__ = ABCMeta

    @abstractmethod
    def lines(self):
        return []

class Float3(object):
    def __init__(self, attr):
        self.attr = '_' + attr

    def __get__(self, obj, objtype):
        arr = getattr(obj, self.attr)
        return np.array((arr[0], arr[1], arr[2], 0.),
                           dtype=clarr.vec.float3)

    def __set__(self, obj, value):
        setattr(obj, self.attr, value)