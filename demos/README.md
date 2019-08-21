# Demos

This folder contains some demonstration applications that serve as test cases
for the FloatSmith framework. Some demos are based on code from other tools,
and many of these are also demos for [ADAPT](https://github.com/LLNL/adapt-fp).
Each demo is described below, and can be run either using its `run.sh` script
(or the `run_all.sh` wrapper) or the FloatSmith invocation string given here
(assuming that the main `floatsmith` script is accessible via your `PATH`.

All of these demos use the batch mode (i.e., `-B`) of FloatSmith for automation
purposes. To run them interactively, just accept all of the default options
except for the ones provided on the command line of the batch mode invocation
string.

All demos that use ADAPT have code annotations already added to serve as
examples of what such annotations should look like.

## Sanity

This is a very trivial example just to show how to use FloatSmith on the most
basic of programs. All it does is add two numbers such that it is sufficient to
store one of them in single precision but the other must be stored in double
precision.

To run: `floatsmith -B --run "./sanity" --adapt`

## Axpy

This is a slightly-more complex example than the sanity example, but not much
more complex. Basically, it extends the idea to a large array of numbers and a
series of operations (resembling a standard "a times x plus y") such that a
speedup can be found on CPUs with vector instructions (e.g., SSE or AVX).

To run: `floatsmith -B --run "./axpy"`

We do not run ADAPT on this example because it isn't really necessary and uses
too much memory to store the large array as active reals for differentiation.

## Sum2pi_x

This is an example from
[CRAFT](https://github.com/crafthpc/craft/tree/master/demo/sum2pi_x).  The
program calculates `PI*X`, where `X` is hard-coded for simplicity. The program
uses an unnecessarily computation-heavy method of calculating `PI*X` for
demonstration purposes. There is an inner loop that sums to `PI`, and then an
outer loop adds that to itself `X` times.

The sensitivity of the test at the end is adjustable using the `#define`
statements at the top. With the default value, double precision produces a
passing final value, while full single precision does not. A mixed precision
version that stores the final sum in double precision can store several
intermediate results (e.g., `tmp` and `acc`) in single precision, which may or
may not result in a speedup depending on your compiler and architecture.

To run: `floatsmith -B --run "./sum2pi_x" --ignore "answer diff error" --adapt`

The invocation ignores several variables that are used to verify the results and
should not be converted.

## Arclength

This is an example from
[Precimonious](https://github.com/corvette-berkeley/precimonious). The program
approximates an integral over an irregular function. One of the variables can be
stored in single precision.

To run: `floatsmith -B --run "./arclength" --ignore "error" --adapt`

## DFT

This is an example from [this paper](https://doi.org/10.1109/FPT.2002.1188677).
The program runs a discrete fourier transform. Several variables can be stored
in single precision.

To run: `floatsmith -B --run "./dft" --ignore "norm" --adapt`

