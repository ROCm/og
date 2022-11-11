
OGDIR ?= /opt/og12/sourcery-2022.09-5/
ROCM_PATH ?= /opt/rocm

TESTNAME    = vectoradd
FILETYPE 	= c

FORT        ?= $(OGDIR)/bin/x86_64-none-linux-gnu-gcc 
TARGET		?= $(shell $(ROCM_PATH)/llvm/bin/offload-arch)
FFLAGS		?= -O3 -fopenmp -foffload=-march=$(TARGET) -D_OG12_DEFAULTS -DOMP -DOMP_TARGET_GPU

LD_LIBRARY_PATH=$(OGDIR)/lib64:$(<ODIR)/lib:$(OGDIR)/x86_64-none-linux-gnu/lib64:$(ROCM_PATH)/hsa/lib:$(LD_LIBRARY_PATH)

# ----- Demo compile and link in one step, no object code saved
$(TESTNAME): $(TESTNAME).$(FILETYPE)
	$(FORT)  $(FFLAGS) $(LFLAGS) $^ -o $@

run: .PHONY $(TESTNAME)
	./$(TESTNAME)

# ----   Demo compile and link in two steps, object saved
$(TESTNAME).o: $(TESTNAME).$(FILETYPE)
	$(FORT) -c $(FFLAGS) -L$(OGDIR)/lib $^

obin:	$(TESTNAME).o 
	$(FORT) $(LFLAGS) $^ -o obin

run_obin: .PHONY obin 
	./obinls

.PHONY: clean
clean:
	rm -rf vectoradd vectoradd.o obinls