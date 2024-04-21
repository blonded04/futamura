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

clean:
	$(RM) *.actual *.bc
