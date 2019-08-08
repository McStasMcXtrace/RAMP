void AtomicAdd(volatile global double *source, const double operand) {
    union {
        unsigned int intVal;
        double doubleVal;
    } newVal;
    union {
        unsigned int intVal;
        double doubleVal;
    } prevVal;
 
    do {
        prevVal.doubleVal = *source;
        newVal.doubleVal = prevVal.doubleVal + operand;
    } while (atomic_cmpxchg((volatile global unsigned int *)source, prevVal.intVal, newVal.intVal) != prevVal.intVal);
}


__kernel void detector(__global double16 *neutrons,
                       __global double8 *intersections, __global uint *iidx,
                       uint const comp_idx, volatile __global double *histogram,
                       double3 const binning, uint const restore_neutron)
{

  uint global_addr = get_global_id(0);
  double16 neutron = neutrons[global_addr];
  double8 intersection = intersections[global_addr];
  double ener_val, min_var, step_var, max_var;

  uint this_iidx, idx;
  this_iidx = iidx[global_addr];

  if (!(this_iidx == comp_idx))
  {
      return;
  }

  if (neutron.sf > 0.)
  {
      return;
  }

  min_var = binning.s0;
  step_var = binning.s1;
  max_var = binning.s2;

  ener_val = pow(length(neutron.s345) / 438.01, 2.0);

  if(min_var<=ener_val && ener_val<=max_var) {    
    idx = round((ener_val -  min_var) / step_var);
   // AtomicAdd(&histogram[idx], neutron.s9);
    neutron.se = idx;
  } else {
    neutron.se = -1;
  }
  
  
  if (restore_neutron == 0) {
    neutron.s012 = intersection.s456;
    neutron.sa += intersection.s7;
    neutron.sf = 1.;
  }

  iidx[global_addr] = 0;
  neutron.sc = comp_idx;
  intersections[global_addr] = (double8)( 0.0f, 0.0f, 0.0f, 100000.0f,
                                         0.0f, 0.0f, 0.0f, 100000.0f );

  neutrons[global_addr] = neutron;
}
