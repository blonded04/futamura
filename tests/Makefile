TESTS=$(sort $(basename $(wildcard *.lama)))

LAMAC=lamac

%.bc: %.lama
	$(LAMAC) -b $<

.PHONY: check $(TESTS)

check: $(TESTS)

$(TESTS): %: %.bc
	@echo $@
	lamac -b $@.lama
	../byterun/byterun $< < $@.input > $@.actual && diff $@.actual $@.expected
#	../spec/spec $< && gcc -m32 -o $@.o $@.lama.s && ./$@.o > $@.actual2 && diff $@.actual2 $@.expected

clean:
	$(RM) *.actual *.bc
