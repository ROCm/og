# For Codebench Lite:
OGDIR     		?= /opt/og12/sourcery-2022.09-5
# For og12 development compiler
#OGDIR      	?= $(HOME)/git/og12/install

ifeq (sourcery,$(findstring sourcery,$(OGDIR)))
	CXXOMP		= x86_64-none-linux-gnu-g++
	OGLIBDIR 	= $(OGDIR)/x86_64-none-linux-gnu/lib64
else
  	CXXOMP	 	= x86_64-none-linux-gnu-g++
  	OGLIBDIR 	= $(OGDIR)/lib64
endif

ROCM_PATH 		?= /opt/rocm
HSALIBDIR 		?= $(ROCM_PATH)/hsa/lib
OLARCH    		?= $(ROCM_PATH)/llvm/bin/offload-arch

CXX         		= $(OGDIR)/bin/$(CXXOMP)
TARGET     		= $(shell $(OLARCH))
CXXFLAGS     	= -O3 -fopenmp -foffload=-march=$(TARGET)
OGLIBS			= -lgomp

.PHONY: all clean realclean

all: multiplyadd

multiplyadd: multiplyadd.o multiplyadd_impl.o
	$(CXX) $(CXXFLAGS) $(OGLIBS) -L$(OGLIBDIR) -Wl,-rpath=$(OGLIBDIR) -o $@ multiplyadd.o multiplyadd_impl.o

multiplyadd.o: multiplyadd.cpp
	$(CXX) $(CXXFLAGS) $(OGLIBS) -L$(OGLIBDIR) -Wl,-rpath=$(OGLIBDIR) -c -o $@ $<

multiplyadd_impl.o: multiplyadd_impl.cpp
	$(CXX) $(CXXFLAGS) $(OGLIBS) -L$(OGLIBDIR) -Wl,-rpath=$(OGLIBDIR) -g -c -o $@ $<

clean:
	rm -f *.o
	rm -f multiplyadd

