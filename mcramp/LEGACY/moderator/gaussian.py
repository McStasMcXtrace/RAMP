import numpy as np
import pyopencl as cl
import pyopencl.array as clarr

import os
import re

class MGaussian():
    def __init__(self, ctx=None, pos=(0, 0, 0), norm=(0, 0, 0), 
                 rad=0, t_dim=(0, 0), t_pos=(0, 0, 0), E=0, dE=0):
        self.pos    = np.array((pos[0], pos[1], pos[2], 0.0), dtype=clarr.vec.float3)
        self.norm   = np.array((norm[0], norm[1], norm[2], 0.0), dtype=clarr.vec.float3)
        self.rad    = np.float32(rad)
        self.t_dim  = np.array((t_dim[0], t_dim[1]), dtype=clarr.vec.float2)
        self.t_pos  = np.array((t_pos[0], t_pos[1], t_pos[2], 0.0), dtype=clarr.vec.float3)
        self.E      = np.float32(E)
        self.dE     = np.float32(dE)

        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'gaussian.cl'), mode='r') as f:
            self.prg = cl.Program(ctx, f.read()).build(options=r'-I "{}/include"'.format(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

    def gen_prg(self, queue, N, neutron_buf, intersection_buf):
        self.prg.generate_neutrons(queue, (N,), None, neutron_buf, intersection_buf,
                                   self.pos,
                                   self.norm,
                                   self.rad,
                                   self.t_dim,
                                   self.t_pos,
                                   self.E,
                                   self.dE)
