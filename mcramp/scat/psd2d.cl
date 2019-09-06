#include "consts.h"

void atomicAdd_g_f(volatile __global float *addr, float val)
{
    union {
        unsigned int u32;
        float        f32;
    } next, expected, current;
	current.f32    = *addr;
    do {
	   expected.f32 = current.f32;
        next.f32     = expected.f32 + val;
		current.u32  = atomic_cmpxchg( (volatile __global unsigned int *)addr, 
                            expected.u32, next.u32);
    } while( current.u32 != expected.u32 );
}

int find_idx(float val, float3 binning) {
    int idx;
    if(binning.s0<=val && val<=binning.s2) {    
        idx = round((val -  binning.s0) / binning.s1);
    } else {
        idx = -1;
    }

    return idx;
}

__kernel void detector(__global float16 *neutrons,
                       __global float8 *intersections, __global uint *iidx,
                       uint const comp_idx, volatile __global float *histogram,
                       float3 const axis1_binning, float3 const axis2_binning, 
                       uint const axis1_numbins, uint const axis2_numbins,
                       uint const shape, uint const restore_neutron)
{

  uint global_addr = get_global_id(0);
  float16 neutron = neutrons[global_addr];
  float8 intersection = intersections[global_addr];

  int this_iidx, axis1_idx, axis2_idx, flattened_idx;
  this_iidx = iidx[global_addr];

  /* Check we are scattering from the intersected component -------------- */
  if (!(this_iidx == comp_idx))
      return;

  /* Check termination flag ---------------------------------------------- */
  if (neutron.sf > 0.f) 
      return;

  /* Perform scattering here --------------------------------------------- */

  // Find axis 1 bin

  if (shape == 0 || shape == 4) { // Plane detector, axis1 is x
    float x_val = intersection.s4;
    axis1_idx = find_idx(x_val, axis1_binning);
  } else if (shape == 1 || shape == 2) { // Banana detector, axis1 is 2theta
    float3 sample_to_det = intersection.s456;
    float theta_val = degrees(atan2(sample_to_det.s0, sample_to_det.s2));
    axis1_idx = find_idx(theta_val, axis1_binning);
  } else if (shape == 3) {
    axis1_idx = find_idx(degrees(atan2(neutron.s3, neutron.s5)), axis2_binning);
  }

  // Find axis 2 bin

  if (shape == 0) { // Plane detector, axis2 is y
    float y_val = intersection.s5;
    axis2_idx = find_idx(y_val, axis2_binning);
  } else if (shape == 1) { // Banana detector, axis2 is alpha
    float3 sample_to_det = intersection.s456;
    float alpha_val = degrees(atan2(sample_to_det.s1, sample_to_det.s2));
    axis2_idx = find_idx(alpha_val, axis2_binning);
  } else if (shape == 2) {
    axis2_idx = find_idx(neutron.sa+intersection.s7, axis2_binning);
  } else if (shape == 3) {
    axis2_idx = find_idx(degrees(atan2(neutron.s4, neutron.s5)), axis2_binning);
  } else if (shape == 4) {
    axis2_idx = find_idx(degrees(atan2(neutron.s3, neutron.s5)), axis2_binning);
  }


  if (!((axis1_idx == -1) || (axis2_idx == -1))) {
    flattened_idx = axis1_idx * axis2_numbins + axis2_idx;
    atomicAdd_g_f(&histogram[flattened_idx], (float)neutron.s9);
  }

  if (restore_neutron == 0) {
    neutron.s012 = intersection.s456;
    neutron.sa += intersection.s7;
    neutron.sf = 1.f;
  }

  iidx[global_addr] = 0;
  neutron.sc = comp_idx;
  intersections[global_addr] = (float8)( 0.0f, 0.0f, 0.0f, 100000.0f,
                                         0.0f, 0.0f, 0.0f, 100000.0f );

  neutrons[global_addr] = neutron;
}