/**
 * sum2pi_x
 *
 * CRAFT demo app. Calculates pi*x in a computationally-heavy way that
 * demonstrates how to use CRAFT without being too complicated.
 *
 */

#include "sum2pi_x.h"

double sum = 0.0;

double pow2(int i)
{
    double power = 1.0;
    while (i --> 0) {
        power *= 2.0;
    }
    return power;
}

void sum2pi_x()
{
    double tmp;
    double acc;
    int i, j;
    for (i=0; i<OUTER; i++) {
        acc = 0.0;
        for (j=1; j<INNER; j++) {

            /* accumulatively calculate pi */
            tmp = PI / pow2(j);
            acc = acc + tmp;
        }
        sum = sum + acc;
    }
}

