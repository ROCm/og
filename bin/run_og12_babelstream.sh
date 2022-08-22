#!/bin/bash

# run_og12_babelstream.sh - compile with OG12 g++  and run babelstream

OGDIR=${OGDIR:-$HOME/git/og12}
OG12DIR=${OG12DIR:-$OGDIR/install}
OG12GXX=${OG12GXX:-$OG12DIR/bin/g++}
ROCMDIR=${ROCMDIR:-/opt/rocm}
GPURUN=${GPURUN:-$ROCMDIR/llvm/bin/gpurun}
DO_CPU_RUNS=0
DO_OVERRIDES=0

#  https://github.com/UoB-HPC/babelstream
BABELSTREAM_REPO=${BABELSTREAM_REPO:-$HOME/git/babelstream}
BABELSTREAM_PATCH=${BABELSTREAM_PATCH:-$HOME/git/og12/og/bin/og12_babelstream.patch}
BABELSTREAM_BUILD=${BABELSTREAM_BUILD:-/tmp/$USER/babelstream}
OFFLOAD_ARCH_BIN=${OFFLOAD_ARCH_BIN:-$ROCMDIR/llvm/bin/offload-arch}

if [ ! -f $OFFLOAD_ARCH_BIN ] ; then 
  echo
  echo "ERROR: ROCM binary missing: $OFFLOAD_ARCH_BIN" 
  echo "       Please install latest ROCM"
  exit 1
fi

_offload_arch=`$OFFLOAD_ARCH_BIN`

if [ ! -d $BABELSTREAM_REPO ]; then
  echo
  echo "ERROR: BabelStream not found in $BABELSTREAM_REPO"
  echo "       Consider running these commands to fetch babelstream:"
  echo
  echo "   cd $HOME/git"
  echo "   git clone https://github.com/UoB-HPC/babelstream"
  echo
  exit 1
fi
if [ ! -f $BABELSTREAM_PATCH ]; then
  echo "ERROR: BabelStream patch not found in $BABELSTREAM_PATCH"
  exit 1
fi
curdir=$PWD
mkdir -p $BABELSTREAM_BUILD
echo cd $BABELSTREAM_BUILD
cd $BABELSTREAM_BUILD
if [ "$1" != "nopatch" ] ; then 
   cp $BABELSTREAM_REPO/src/main.cpp .
   cp $BABELSTREAM_REPO/src/Stream.h .
   cp $BABELSTREAM_REPO/src/omp/OMPStream.cpp .
   cp $BABELSTREAM_REPO/src/omp/OMPStream.cpp OMPStream.orig.cpp
   cp $BABELSTREAM_REPO/src/omp/OMPStream.h .
   echo "Applying patch: $BABELSTREAM_PATCH"
   patch < $BABELSTREAM_PATCH
fi
omp_src="main.cpp OMPStream.cpp"
omp_src_orig="main.cpp OMPStream.orig.cpp"
thisdate=`date`
echo | tee a results.txt
echo "=========> RUNDATE:  $thisdate" | tee -a results.txt
echo "=========> GPU:      $_offload_arch" || tee -a results.txt
echo | tee -a results.txt
echo "=========> RUN:      1.  og12 OFFLOAD DEFAULTS" | tee -a results.txt
og12_flags="-O3 -fopenmp -foffload=-march=$_offload_arch -D_OG12_DEFAULTS -DOMP -DOMP_TARGET_GPU"
   export LD_LIBRARY_PATH=$OG12DIR/lib64:$ROCMDIR/hsa/lib
   export OMP_TARGET_OFFLOAD=MANDATORY
   unset GCN_DEBUG
   export GCN_DEBUG=1
   EXEC=omp-stream-og12
   rm -f $EXEC
   cmd="$OG12GXX -v $og12_flags $omp_src -o $EXEC"
   echo "=========> CC CMD:   $cmd" | tee -a results.txt
   echo
   echo env >compile.log
   env >>compile.log
   echo "==================================" >>compile.log
   echo $cmd >>compile.log
   echo >>compile.log
   $cmd >compile.stdout 2>>compile.log
   rc=$?
   if [ $rc == 0 ]; then
      if [ -f $GPURUN ] ; then
         echo $GPURUN ./$EXEC >> results.txt
         $GPURUN ./$EXEC 2>&1 | tee -a results.txt
      else
         echo ./$EXEC >> results.txt
         ./$EXEC 2>&1 | tee -a results.txt
      fi
   else
      echo "ERROR: COMPILATION FAILED with rc=$rc ."
      echo "       See $BABELSTREAM_BUILD/compile.log"
      exit 1
   fi
   unset OMP_TARGET_OFFLOAD

echo | tee -a results.txt
echo "=========> RUN:      2. clang no simd" | tee -a results.txt
_clangcc="$ROCMDIR/llvm/bin/clang++"
_clang_omp_flags="-std=c++11 -O3 -fopenmp -fopenmp-targets=amdgcn-amd-amdhsa -Xopenmp-target=amdgcn-amd-amdhsa -march=$_offload_arch -DOMP -DOMP_TARGET_GPU -D_DEFAULTS_NOSIMD"
echo "=========> COMPILER: $_clangcc" | tee -a results.txt
   export OMP_TARGET_OFFLOAD=MANDATORY
   EXEC=omp-stream-clang
   rm -f $EXEC
   echo $_clangcc $_clang_omp_flags $omp_src -o $EXEC | tee -a results.txt
   $_clangcc $_clang_omp_flags $omp_src -o $EXEC
   if [ $? -ne 1 ]; then
     ./$EXEC 2>&1 | tee -a results.txt
   fi

if [ $DO_OVERRIDES  == 1 ] ; then 
   echo | tee -a results.txt
   echo "=========> RUN:      3. og12 with OVERRIDES" | tee -a results.txt
   echo "=========> COMPILER: $OG12GXX" | tee -a results.txt
   og12_flags="-O3 -fopenmp -foffload=-march=$_offload_arch -D_OG12_OVERRIDE -DNUM_THREADS=1024 -DNUM_TEAMS=240 -DOMP -DOMP_TARGET_GPU"
   export LD_LIBRARY_PATH=$OG12DIR/lib64:$ROCMDIR/hsa/lib
   export OMP_TARGET_OFFLOAD=MANDATORY
   unset GCN_DEBUG
   #export GCN_DEBUG=1
   EXEC=omp-stream-og12-overrides
   rm -f $EXEC
   echo $OG12GXX $og12_flags $omp_src -o $EXEC | tee -a results.txt
   $OG12GXX $og12_flags $omp_src -o $EXEC
   if [ $? -ne 1 ]; then
     ./$EXEC 2>&1 | tee -a results.txt
   fi
   unset OMP_TARGET_OFFLOAD
fi

if [ $DO_CPU_RUNS == 1 ] ; then 
   echo | tee -a results.txt
   echo "=========> RUN:      4. og12 OPENMP CPU" | tee -a results.txt
   echo "=========> COMPILER: $OG12GXX" | tee -a results.txt
   omp_flags_cpu="-O3 -fopenmp -DOMP"
   unset OMP_TARGET_OFFLOAD
   export LD_LIBRARY_PATH=$OG12DIR/lib64:$ROCMDIR/hsa/lib
   EXEC=omp-stream-og12-cpu
   rm -f $EXEC
   echo $OG12GXX $omp_flags_cpu $omp_src -o $EXEC
   $OG12GXX $omp_flags_cpu $omp_src -o $EXEC
   if [ $? -ne 1 ]; then
     ./$EXEC 2>&1 | tee -a results.txt
   fi

   echo | tee -a results.txt
   echo "=========> RUN:      5. gcc OPENMP CPU" | tee -a results.txt
   GXX_VERSION=`g++ --version | grep -m1 "g++" | awk '{print $4}'`
   echo "=========> COMPILER: g++ $GXX_VERSION" | tee -a results.txt
   omp_flags_cpu="-O3 -fopenmp -DOMP"
   unset OMP_TARGET_OFFLOAD
   unset LD_LIBRARY_PATH
   EXEC=omp-stream-gxx-cpu
   rm -f $EXEC
   echo g++ $omp_flags_cpu $omp_src_orig -o $EXEC | tee -a results.txt
   g++ $omp_flags_cpu $omp_src_orig -o $EXEC
   if [ $? -ne 1 ]; then
     ./$EXEC 2>&1 | tee -a results.txt
   fi
fi

echo
echo "DONE. See results at end of file $BABELSTREAM_BUILD/results.txt"
cd $curdir
