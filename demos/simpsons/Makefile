TARGETS = simpsons

CXXFLAGS += -g -O3 -Wall -Wno-unknown-pragmas
LDFLAGS += -lm

all: $(TARGETS)

simpsons: simpsons.cpp
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -rf $(TARGETS) *.dSYM

