CXXFLAGS+=-g -O3 -std=c++11 -Wall -Wno-unknown-pragmas
LDFLAGS+=-lm

all: dft

dft: dft.cpp
	$(CXX) -DDEBUG $(CXXFLAGS) -o $@ $(LDFLAGS) $<

clean:
	rm -rf dft

