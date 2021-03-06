__kernel void intersect_sphere(__global float16* neutrons, 
      __global float8* intersections, __global uint* iidx,
      uint const comp_idx, float3 const sphere_pos,
      float const sphere_radius) {

  uint global_addr = get_global_id(0);
  float16 neutron = neutrons[global_addr];
  float8 intersection;
  float3 pos, vel, s_pos;
  float s_rad, a, b, c, d1, d2, quotient;
 
  if (neutron.sf > 0.) {
    return;
  }

  if (neutron.sc == comp_idx) {
    return;
  }

  pos = neutron.s012;
  vel = neutron.s345;

  s_pos = sphere_pos;
  s_rad = sphere_radius;

  intersection = intersections[global_addr];

  a = dot(vel, vel);
  b = 2.0*(dot(vel, (pos - s_pos)));
  c = dot((pos - s_pos), (pos - s_pos)) - s_rad*s_rad;
  quotient = b*b - 4.0*a*c;

  if (quotient > 0) {
    d1 = (-b - sqrt(quotient)) / (2.*a);
    d2 = (-b + sqrt(quotient)) / (2.*a);
    if (d1 < intersection.s3 && d1 > 0.) {
      intersection.s012 = pos + d1*vel;
      intersection.s3 = d1;
      iidx[global_addr] = comp_idx;
      intersection.s456 = pos + d2*vel;
      intersection.s7 = d2;
    }
  }

  intersections[global_addr] = intersection;
  neutrons[global_addr] = neutron;
}