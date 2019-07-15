#include <stdio.h>

#define N 100000000         // vector size
#define A 10.0              // scalar
#define I 20                // # of scaling iterations
#define X 0.00000003e-20    // initial vector value
#define Y 1.00000003        // initial sum value

double a = A;               // can be float
double x[N];                // can be float
double y[N];                // must be double

int main()
{
#   pragma adapt begin

    for (int j=0; j<N; j++) {           // initialize x and y
        x[j] = X;
        y[j] = Y;
    }

    for (int j=0; j<N; j++) {           // compute a*x multiple times
        for (int i=0; i<I; i++) {
            x[j] *= a;
        }
    }

    for (int j=0; j<N; j++) {           // compute x+y
        y[j] += x[j];
    }

#   pragma adapt output y[0] 1e-8
#   pragma adapt end
    printf("%.8f\n", (double)y[0]);     // should print 1.00000006
    return 0;
}
