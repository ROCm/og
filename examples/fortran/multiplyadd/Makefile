# For Codebench Lite:
OGDIR     ?= /opt/og12/sourcery-2022.09-5
# For og12 development compiler
#OGDIR      ?= $(HOME)/git/og12/install

ifeq (sourcery,$(findstring sourcery,$(OGDIR)))
	GFORTRAN  = x86_64-none-linux-gnu-gfortran
	OGLIBDIR  = $(OGDIR)/x86_64-none-linux-gnu/lib64
else
  	GFORTRAN  = x86_64-pc-linux-gnu-gfortran
  	OGLIBDIR  = $(OGDIR)/lib64
endif

ROCM_PATH ?= /opt/rocm
HSALIBDIR ?= $(ROCM_PATH)/hsa/lib
OLARCH    ?= $(ROCM_PATH)/llvm/bin/offload-arch

FC         = $(OGDIR)/bin/$(GFORTRAN)
TARGET     = $(shell $(OLARCH))
FFLAGS     = -O3 -fopenmp -foffload=-march=$(TARGET)
OGLIBS     = -lgomp -lgfortran -lgcc_s -lquadmath 

.PHONY: all clean realclean

all: multiplyadd

multiplyadd: multiplyadd.o multiplyadd_impl.o
	$(FC) $(FFLAGS) $(OGLIBS) -L$(OGLIBDIR) -Wl,-rpath=$(OGLIBDIR) -o $@ multiplyadd.o multiplyadd_impl.o

multiplyadd.o: multiplyadd.f90 multiplyadd_impl.mod
	$(FC) $(FFLAGS) $(OGLIBS) -L$(OGLIBDIR) -Wl,-rpath=$(OGLIBDIR) -c -o $@ $<

multiplyadd_impl.mod: multiplyadd_impl.o
multiplyadd_impl.o: multiplyadd_impl.f90
	$(FC) $(FFLAGS) $(OGLIBS) -L$(OGLIBDIR) -Wl,-rpath=$(OGLIBDIR) -g -c -o $@ $<

clean:
	rm -f *.o
	rm -f *.mod

realclean: clean
	rm -f *.bak *~
	rm -f axpy

