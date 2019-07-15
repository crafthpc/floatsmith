/**
 * sum2pi_x
 *
 * CRAFT demo app. Calculates pi*x in a computationally-heavy way that
 * demonstrates how to use CRAFT without being too complicated.
 *
 */

#include "sum2pi_x.h"

extern double sum;

int main()
{
#   pragma adapt begin
    sum2pi_x();
#   pragma adapt output sum (EPS*(OUTER*PI))
#   pragma adapt end

    double answer = (double)OUTER * PI;             /* correct answer */
    double diff = (double)answer-(double)sum;
    double error = ABS(diff);

    if ((double)error < (double)EPS*answer) {
        printf("SUM2PI_X - SUCCESSFUL!\n");
    } else {
        printf("SUM2PI_X - FAILED!!!\n");
    }

    return 0;
}

