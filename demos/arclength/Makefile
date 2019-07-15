TARGETS = arclength

CXXFLAGS += -g -O3 -Wall -Wno-unknown-pragmas
LDFLAGS += -lm

all: $(TARGETS)

arclength: arclength.cpp
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

run: $(TARGETS)
	@$(foreach trg, $(TARGETS), echo -e "\n== $(trg) ==" && ./$(trg);)

clean:
	rm -rf $(TARGETS) *.dSYM

