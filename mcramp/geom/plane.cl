__kernel void intersect_plane(__global float16* neutrons,
    __global float8* intersections, __global uint* iidx,
    uint const comp_idx, float const width, 
    float const height) {

    uint global_addr        = get_global_id(0);
    float16 neutron         = neutrons[global_addr];
    float8 intersection     = intersections[global_addr];

    /* Check termination flag */
    if (neutron.sf > 0.) 
        return;

    if (neutron.sc == comp_idx) {
        return;
    }

    /* Perform raytracing here */

    float3 vel = neutron.s345;
    float3 pos = neutron.s012;

    float t = (-pos.s2) / vel.s2;
    float x = pos.s0 + t*vel.s0;
    float y = pos.s1 + t*vel.s1;

    if ((fabs(x) < width / 2) && (fabs(y) < height / 2)
        && t < intersection.s3
        && t < intersection.s7
        && t > 0
        && dot(vel, (float3)( 0.0f, 0.0f, 1.0f )) > 0.) {

        intersection.s012 = pos + t*vel;
        intersection.s456 = pos + t*vel;
        intersection.s3   = t;
        intersection.s7   = t;

        iidx[global_addr] = comp_idx;
    }

    /* ----------------------- */

    /* Update global memory */
    intersections[global_addr] = intersection;
    neutrons[global_addr]      = neutron;
}