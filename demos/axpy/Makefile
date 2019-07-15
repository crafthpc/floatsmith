CXXFLAGS+=-g -Wall -Wno-unknown-pragmas -O2 -ftree-vectorize -fopt-info-vec-optall=optimize.log

all: axpy

axpy: axpy.cpp
	$(CXX) $(CXXFLAGS) -o $@ $^

clean:
	rm -rf axpy

