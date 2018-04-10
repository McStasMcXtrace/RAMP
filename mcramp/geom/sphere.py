from .gprim import GPrim #pylint: disable=E0401

import numpy as np
import pyopencl as cl
import pyopencl.array as clarr

import os

class GSphere(GPrim):
    def __init__(self, radius=0, position=(0, 0, 0), idx=0, ctx=None):
        self.radius     = np.float32(radius)
        self.position   = position
        self.idx        = idx

        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sphere.cl'), mode='r') as f:
            self.prg = cl.Program(ctx, f.read()).build(options=r'-I "{}\include"'.format(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


    def intersect_prg(self, queue, N, neutron_buf, intersection_buf, iidx_buf):
        self.prg.intersect_sphere(queue, (N,),
                                  None,
                                  neutron_buf,
                                  intersection_buf,
                                  iidx_buf,
                                  np.uint32(self.idx),
                                  self.position,
                                  self.radius).wait()