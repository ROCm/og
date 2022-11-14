OGDIR 		?= /opt/og12/sourcery-2022.09-5/
ROCM_PATH 	?= /opt/rocm

FC        	= $(OGDIR)/bin/x86_64-none-linux-gnu-gfortran
TARGET		= $(shell $(ROCM_PATH)/llvm/bin/offload-arch)
CXXFLAGS	= -O3 -fopenmp -foffload=-march=$(TARGET) -D_OG12_DEFAULTS -DOMP -DOMP_TARGET_GPU

.PHONY: all clean realclean

all: multiplyadd

multiplyadd: multiplyadd.o multiplyadd_impl.o
	$(FC) $(FFLAGS) -o $@ multiplyadd.o multiplyadd_impl.o

multiplyadd.o: multiplyadd.f90 multiplyadd_impl.mod
	$(FC) $(FFLAGS) -c -o $@ $<

multiplyadd_impl.mod: multiplyadd_impl.o
multiplyadd_impl.o: multiplyadd_impl.f90
	$(FC) $(FFLAGS) -g -c -o $@ $<

clean:
	rm -f *.o
	rm -f *.mod

realclean: clean
	rm -f *.bak *~
	rm -f axpy

