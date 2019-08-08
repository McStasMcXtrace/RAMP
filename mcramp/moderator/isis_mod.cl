#include "rand.h"

int find_closest_in_cdf(__global double* arr, int arrlen, double val) {
  // Find index of last element in arr which is less than val
  for (int i = 0; i < arrlen; i++) {
    if ((arr[i] - val) > 0.0) {
      return i - 1;
    }
  }

  return 0;
}

__kernel void generate_neutrons(__global double16* neutrons,
    __global double8* intersections, double2 const mod_dim,
    double2 const target_dim, double const target_dist, double const E_min,
    double const E_max, int const num_time_bins, int const num_ener_bins,
    __global double* flux, __global double* time_bins, __global double* ener_bins,
    global double* E_int, double const total, double const str_area,
    double const time_offset, int const num_sim) {

  int global_addr, idx, Epnt, Tpnt, interpol_start, interpol_end;
  double deviate, time_val, time_range, time_spread, R, ener_val, ener_spread, 
  accumulator, Pj, vel, Dx, Dy;
  double16 neutron;
  
  global_addr = get_global_id(0);
  neutron = neutrons[global_addr];

  deviate = total * rand(&neutron, global_addr);

  idx = find_closest_in_cdf(flux, num_time_bins * num_ener_bins, deviate);

  Epnt = find_closest_in_cdf(E_int, num_ener_bins, deviate);
  Tpnt = fmod((double)idx, (double)num_time_bins);

  if(Tpnt >= num_time_bins-1) {
    Tpnt -= 1;
  }

  time_val = time_bins[Tpnt];
  time_range = time_bins[Tpnt + 1] - time_bins[Tpnt];
  time_spread = flux[Epnt * num_time_bins + Tpnt + 1] - flux[Epnt * num_time_bins + Tpnt];
  R = deviate - flux[Epnt * num_time_bins + Tpnt];
  R /= time_spread;
  time_val += time_range * R;

  ener_val = ener_bins[Epnt];
  ener_spread = E_int[Epnt+1] - E_int[Epnt];

  interpol_start = (Epnt > 3) ? Epnt - 3 : 0;
  interpol_end = ((num_ener_bins - Epnt - 1) > 3) ? Epnt + 3 : (num_ener_bins - 1);
  
  deviate = E_int[Epnt] + ener_spread * rand(&neutron, global_addr);
  accumulator = 0.0;
  for (int i = interpol_start; i <= interpol_end; i++) {
    Pj = 1.0;
    for (int j = interpol_start; j <= interpol_end; j++) {
      if (j != i) {
        Pj *= (deviate - E_int[j]) / (E_int[i] - E_int[j]);
      } else {
        Pj *= 1;
      }
    }
    Pj *= ener_bins[i];

    accumulator += Pj;
  }
  ener_val = accumulator;

  neutron.s0 = mod_dim.x*(0.5 - rand(&neutron, global_addr));
  neutron.s1 = mod_dim.y*(0.5 - rand(&neutron, global_addr));
  neutron.s2 = 0.0;

  vel = 437.393377*sqrt(ener_val);
  Dx = target_dim.x*(0.5 - rand(&neutron, global_addr)) - neutron.s0;
  Dy = target_dim.y*(0.5 - rand(&neutron, global_addr)) - neutron.s1;
  
  neutron.s345 = vel*normalize((double3)( Dx, Dy, target_dist ));

  // Initialize weight
  // TODO: with buffer chunking this will exaggerate the intensity by the number
  // of buffer chunks (assuming equally sized chunks). Must find a way to fix!
  neutron.s9 = str_area*total*6.2415093e+12 / num_sim;

  // Initialize time
  neutron.sa = time_val;

  // Revive terminated neutrons
  neutron.sf = 0.;

  neutrons[global_addr] = neutron;
  intersections[global_addr] = (double8)( 0.0f, 0.0f, 0.0f, 100000.0f,
                                         0.0f, 0.0f, 0.0f, 100000.0f );
}