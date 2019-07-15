CXXFLAGS+=-g -O3 -Wall -Wno-unknown-pragmas

all: sum2pi_x

sum2pi_x: sum2pi_x.o main.o
	$(CXX) -o $@ $^ $(LDFLAGS)

%.o: %.cpp sum2pi_x.h
	$(CXX) $(CXXFLAGS) -c $<

clean:
	rm -rf sum2pi_x *.o

