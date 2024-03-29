#!/bin/bash

# run_og13_babelstream.sh - compile with OG13 g++  and run babelstream

OGDIR=${OGDIR:-/home/grodgers/git/og13/install}
OGGXX=${OGGXX:-$OGDIR/bin/g++}
if [ -d $OGDIR/lib64 ] ; then
  OGLIB=${OGLIB:-$OGDIR/lib64}
else
  OGLIB=${OGLIB:-$OGDIR/x86_64-none-linux-gnu/lib64}
  if [ ! -d $OGLIB ] ; then
    echo "WARING $OGLIB NOT FOUND "
  fi
fi
ROCMDIR=${ROCMDIR:-/opt/rocm}

#  For current build of OG13 do something like this
#    export OGDIR=~/git/og13/install
#    export OGGXX=~/git/og13/install/bin/g++
#    export OGLIB=~/git/og13/install/lib64

#  https://github.com/UoB-HPC/babelstream
BABELSTREAM_REPO=${BABELSTREAM_REPO:-$HOME/git/babelstream}
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
curdir=$PWD
mkdir -p $BABELSTREAM_BUILD
echo cd $BABELSTREAM_BUILD
cd $BABELSTREAM_BUILD
if [ "$1" != "nocopy" ] ; then 
   cp $BABELSTREAM_REPO/src/main.cpp .
   cp $BABELSTREAM_REPO/src/Stream.h .
   cp $BABELSTREAM_REPO/src/omp/OMPStream.cpp .
   cp $BABELSTREAM_REPO/src/omp/OMPStream.cpp OMPStream.orig.cpp
   cp $BABELSTREAM_REPO/src/omp/OMPStream.h .
fi
omp_src="main.cpp OMPStream.cpp"
omp_src_orig="main.cpp OMPStream.orig.cpp"
thisdate=`date`
echo | tee a results.txt
echo "=========> RUNDATE:  $thisdate" | tee -a results.txt
echo "=========> GPU:      $_offload_arch" || tee -a results.txt
echo | tee -a results.txt
echo "=========> RUN:      1.  og13 OFFLOAD DEFAULTS" | tee -a results.txt
og13_flags="-O3 -fopenmp -foffload=-march=$_offload_arch -DOMP -DOMP_TARGET_GPU"
   export LD_LIBRARY_PATH=$OGLIB:$ROCMDIR/hsa/lib
   export OMP_TARGET_OFFLOAD=MANDATORY
   #unset GCN_DEBUG
   #export GCN_DEBUG=1
   EXEC=omp-stream-og13
   rm -f $EXEC
   cmd="$OGGXX -v $og13_flags $omp_src -o $EXEC"
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
      echo ./$EXEC >> results.txt
      ./$EXEC 2>&1 | tee -a results.txt
   else
      echo "ERROR: COMPILATION FAILED with rc=$rc ."
      echo "       See $BABELSTREAM_BUILD/compile.log"
      exit 1
   fi
   unset OMP_TARGET_OFFLOAD

echo
echo "DONE. See results at end of file $BABELSTREAM_BUILD/results.txt"
cd $curdir
