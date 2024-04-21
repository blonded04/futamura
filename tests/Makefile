TESTS=$(sort $(basename $(wildcard *.lama)))

LAMAC=lamac

%.bc: %.lama
	$(LAMAC) -b $<

.PHONY: check $(TESTS)

check: $(TESTS)

$(TESTS): %: %.bc
	@echo $@
	lamac -b $@.lama
	# ../byterun/byterun $< < $@.input > $@.actual_inter && diff $@.actual_inter $@.expected
	../spec/spec $< > $@.S && gcc -m32 -o $@ $@.S ../runtime/runtime.a && \
		./$@ > $@.actual && diff $@.actual $@.expected

clean:
	$(RM) *.actual *.actual_inter *.bc *.S *.o
