#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define PI 3.14159265358979323846

#define N 5000

typedef unsigned long int uint_t;

double in_real[N];
double in_imag[N];
double out_real[N];
double out_imag[N];

void dft()
{
    double W_real[N];
    double W_imag[N];
    double arg = 2.0*PI / (double)N;        // NOTE: added arg calculation
                                            //       (not in paper)

    /* Generation of coefficients W */
    for (uint_t i = 0; i < N; i++) {        // NOTE: fixed typo in paper here
        W_real[i] =  cos(arg * (double)i);
        W_imag[i] = -sin(arg * (double)i);
    }

    /* The main computation kernel */
    for (uint_t k = 0; k < N; k++) {        // Outer loop
        out_real[k] = in_real[k];           // NOTE: added array references
        out_imag[k] = in_imag[k];           //       (were scalar in paper)
        for (uint_t n = 0; n < N; n++) {    // Inner loop
            uint_t p = (n * k) % N;
            out_real[k] = out_real[k] + in_real[n] * W_real[p] - in_imag[n] * W_imag[p];
            out_imag[k] = out_imag[k] + in_real[n] * W_imag[p] + in_imag[n] * W_real[p];
        }
    }
}

double sgn(const double x)
{
    // return -1 if x is negative, 0 if it is zero and 1 if it is positive
    // NOTE: this is not differentiable; it is only used to generate inputs!
    return ((x > 0.0) - (x < 0.0));
}

int main(int argc, char* argv[])
{
    /* Generate inputs */
    for (uint_t i = 0; i < N; i++) {
        // scale i to [0,2*pi)
        double x = ((2.0*PI) / (double)N) * (double)i;

        // minor variation on a square wave (the classic FFT encoding example)
        in_real[i] = sgn(sin(x+1.0))+cos(x);
        in_imag[i] = sgn(cos(x+1.0))+sin(x);
    }

#pragma adapt begin

    /* Run discrete fourier transform routine */
    dft();

    /* Calculate and print output norm */
    double norm = 0.0;
    for (uint_t i = 0; i < N; i++) {
        norm += out_real[i] * out_real[i];
    }
    norm = sqrt(norm);
    printf("%.6e\n", (double)norm);

#pragma adapt output norm 5e-6
#pragma adapt end

    return 0;
}

