FLAGS=-m32 -g2 -fstack-protector-all -std=c++17

all: spec.o
	$(CXX) $(FLAGS) -no-pie -o spec spec.o

spec.o: spec.cc
	$(CXX) $(FLAGS) -no-pie -g -c spec.cc

clean:
	$(RM) *.a *.o *~ spec
