/**
 * sum2pi_x
 *
 * CRAFT demo app. Calculates pi*x in a computationally-heavy way that
 * demonstrates how to use CRAFT without being too complicated.
 *
 */

#ifndef __SUM2PI_X
#define __SUM2PI_X

#include <stdio.h>

/* macros */
#define ABS(x) ( ((x) < 0.0) ? (-(x)) : (x) )

/* constants */
#define PI     3.1415926535897932384626433832795
#define EPS    5e-7

/* loop  iterations; OUTER is X */
#define INNER    25
#define OUTER    2000

void sum2pi_x();

#endif

