#include "ref.h"
#include "consts.h"

__kernel void guide_scatter(__global float16* neutrons,
    __global float8* intersections, __global uint* iidx,
    uint const comp_idx, float3 const g_pos, 
    float const w1, float const h1,
    float const w2, float const h2, float const l,
    float const R0, float const Qc, float const alpha,
    float const m, float const W, uint const max_bounces) {

    uint global_addr        = get_global_id(0);
    float16 neutron         = neutrons[global_addr];
    uint this_iidx          = iidx[global_addr];

    /* Check we are scattering from the intersected component */
    if (!(this_iidx == comp_idx)) {
        return;
    }

    /* Check termination flag */
    if (neutron.sf > 0.)  {
        return;
    }

    /* Perform scattering here */

    float3 n1v, n2v, n1h, n2h, O1v, O2v, O1h, O2h, pos, vel;
    float t1v, t2v, t1h, t2h, texit, q, tmin;
    float refl = 1;

    uint attempts = 0;
    bool finished = false;

    n1v = (float3)( l, 0.0f, (w2 - w1)/2.0f );
    n2v = (float3)( -l, 0.0f, (w2 - w1)/2.0f );
    n1h = (float3)( 0.0f, l, (h2 - h1)/2.0f );
    n2h = (float3)( 0.0f, -l, (h2-h1)/2.0f );
    O1v = (float3)( -w1/2.0f, 0.0f, 0.0f );
    O2v = (float3)( w1/2.0f, 0.0f, 0.0f );
    O1h = (float3)( 0.0f, -h1/2.0f, 0.0f );
    O2h = (float3)( 0.0f, h1/2.0f, 0.0f );

    float3 norms[4] = {n1v, n2v, n1h, n2h};

   while (!finished && attempts < max_bounces) {
        attempts+=1;

        pos = neutron.s012 - g_pos;
        vel = neutron.s345;

        t1h = dot((O1h - pos), n1h) / dot(vel, n1h);
        t2h = dot((O2h - pos), n2h) / dot(vel, n2h);
        t1v = dot((O1v - pos), n1v) / dot(vel, n1v);
        t2v = dot((O2v - pos), n2v) / dot(vel, n2v);
        texit = (l - pos.s2) / neutron.s5;

        /* 0: 1h, 1: 2h, 2: 1v, 3: 2v, 4: exit */

        float times[5] = {t1h, t2h, t1v, t2v, texit};

        tmin=1000.0f;
        uint mindex=0;

        for(uint i=0; i < 5; i++) {
            if ((times[i] < tmin) && (times[i] > 0.0f)) {
                tmin = times[i];
                mindex = i;
            }
        }

        neutron.s012 = (pos + g_pos) + tmin*vel;
        neutron.sa += tmin;

        if (mindex == 4) { 
            finished = true;
        } else {
            q = V2K*length(vel);

            refl = reflectivity_func(q, R0, Qc, alpha, m, W);

            neutron.s345 = vel - (dot(2*norms[mindex], vel) 
                            / (length(norms[mindex])*length(norms[mindex])))
                            * norms[mindex];
            neutron.s9  *= refl;
        }
    }

    /* ----------------------- */

    /* Update global memory and reset intersection */
    iidx[global_addr] = 0;
    neutron.sc = comp_idx;

    neutrons[global_addr]      = neutron;
    intersections[global_addr] = (float8)( 0.0f, 0.0f, 0.0f, 100000.0f,
                                         0.0f, 0.0f, 0.0f, 100000.0f );

}