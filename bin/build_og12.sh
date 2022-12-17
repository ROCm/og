#!/bin/bash
#
#  build_og12.sh: script to configure and build gcc for amdgcn
#
#  This runs a long time so run this script with nohup like this:
#    nohup build_og12.sh
#  or 
#   ./build_og12.sh 2>&1 | tee build.out
#
#  Script follows some instruction given at https://gcc.gnu.org/wiki/Offloading
#  Written by Greg Rodgers

# Set number of make jobs to speed this up. 
make_jobs=12

# This OGDIR will contain multiple git repositories and build directories 
OGDIR=${OGDIR:-$HOME/git/og12}

# OG_INSTALL_DIR points to the final installation directory used for "make install"
OG_INSTALL_DIR=${OG_INSTALL_DIR:-$OGDIR/install}

# This script requires ROCMLLVM.
ROCM_PATH=${ROCM_PATH:-/opt/rocm}
ROCMLLVM=${ROCMLLVM:-$ROCM_PATH/llvm}
if [[ ! -f "${ROCMLLVM}/bin/llvm-mc" ]] ; then 
   echo "ERROR:  missing ${ROCMLLVM}/bin/llvm-mc check LLVM installation"
   exit 1
fi

echo " ============================ OG12BSTEP: Initialize  ================="
mkdir -p $OGDIR
if [ $? != 0 ] ; then 
   echo "ERROR: No update access to $OGDIR"
   exit 1
fi
gccmaindir=$OGDIR/gcc
if [ -d $gccmaindir ] ; then 
   # Get updates
   cd $gccmaindir
   git pull
   git status
else
   # get a new clone of the source 
   echo cd $OGDIR
   cd $OGDIR
   echo git clone git://gcc.gnu.org/git/gcc.git
   git clone git://gcc.gnu.org/git/gcc.git
   cd $gccmaindir
   git checkout devel/omp/gcc-12
   git pull
fi

if [ -d $OGDIR/newlib-cygwin ] ; then 
   # Get updates if any
   echo cd $OGDIR/newlib-cygwin
   cd $OGDIR/newlib-cygwin
   echo git pull
   git pull
else
   cd $OGDIR
   echo git clone git://sourceware.org/git/newlib-cygwin.git
   git clone git://sourceware.org/git/newlib-cygwin.git
fi
[ ! -L $gccmaindir/newlib ] && ln -sf $OGDIR/newlib-cygwin/newlib $gccmaindir/newlib

# wget tarballs for other components
cd $gccmaindir
if [ ! -L isl ] ; then 
   echo -- getting isl
   wget https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2
   bunzip2 isl-0.24.tar.bz2
   tar -xf isl-0.24.tar
   ln -sf isl-0.24 isl
fi
if [ ! -L gmp ] ; then 
   echo -- getting gmp
   wget https://gcc.gnu.org/pub/gcc/infrastructure/gmp-6.2.1.tar.bz2
   bunzip2 gmp-6.2.1.tar.bz2
   tar -xf gmp-6.2.1.tar
   ln -sf gmp-6.2.1 gmp
fi
if [ ! -L mpc ] ; then 
   echo -- getting mpc
   wget https://gcc.gnu.org/pub/gcc/infrastructure/mpc-1.2.1.tar.gz
   gunzip  mpc-1.2.1.tar.gz
   tar -xf mpc-1.2.1.tar
   ln -sf mpc-1.2.1 mpc 
fi
if [ ! -L mpfr ] ; then 
   echo -- getting mpfr
   wget https://gcc.gnu.org/pub/gcc/infrastructure/mpfr-4.1.0.tar.bz2
   bunzip2 mpfr-4.1.0.tar.bz2
   tar -xf mpfr-4.1.0.tar
   ln -sf mpfr-4.1.0 mpfr
fi

[ -d $OG_INSTALL_DIR ] && rm -rf $OG_INSTALL_DIR
mkdir -p $OG_INSTALL_DIR/amdgcn-amdhsa/bin
rsync -av $ROCMLLVM/bin/llvm-ar $OG_INSTALL_DIR/amdgcn-amdhsa/bin/ar
rsync -av $ROCMLLVM/bin/llvm-ar $OG_INSTALL_DIR/amdgcn-amdhsa/bin/ranlib
rsync -av $ROCMLLVM/bin/llvm-mc $OG_INSTALL_DIR/amdgcn-amdhsa/bin/as
rsync -av $ROCMLLVM/bin/llvm-nm $OG_INSTALL_DIR/amdgcn-amdhsa/bin/nm
rsync -av $ROCMLLVM/bin/lld     $OG_INSTALL_DIR/amdgcn-amdhsa/bin/ld
echo " ============================ OG12BSTEP: Configure device ================="
cd $OGDIR

# Determine commit ID
pushd gcc
GIT_ID=$(git rev-parse HEAD)
popd

#  Uncomment next line to start build from scratch
[ -d ./build-amdgcn ] && rm -rf build-amdgcn
mkdir -p build-amdgcn
echo cd build-amdgcn
cd build-amdgcn
WITHOPTS="--with-gmp --with-mpfr --with-mpc "
echo "../gcc/configure --prefix=$OG_INSTALL_DIR -v --target=amdgcn-amdhsa --enable-languages=c,lto,fortran --disable-sjlj-exceptions --with-newlib --enable-as-accelerator-for=x86_64-pc-linux-gnu --with-build-time-tools=$OG_INSTALL_DIR/amdgcn-amdhsa/bin "  | tee ../amdgcnconfig.stdout
   ../gcc/configure --prefix=$OG_INSTALL_DIR -v --target=amdgcn-amdhsa --enable-languages=c,lto,fortran --disable-sjlj-exceptions --with-newlib --enable-as-accelerator-for=x86_64-pc-linux-gnu --with-build-time-tools=$OG_INSTALL_DIR/amdgcn-amdhsa/bin  2>&1 | tee ../amdgcnconfig.stdout
if [ $? != 0 ] ; then 
   echo "ERROR  configure amdgcn compiler failed"
   exit 1
fi
echo " ============================ OG12BSTEP: device make ================="
make -j$make_jobs
if [ $? != 0 ] ; then 
   echo "ERROR  make amdgcn compiler failed"
   exit 1
fi
echo " ============================ OG12BSTEP: device make install ================="
make install 
echo "Removing symlink for newlib rm $gccmaindir/newlib"
rm $gccmaindir/newlib

cd $OGDIR
#  Uncomment next line to start build from scratch
[ -d ./build-host ] && rm -rf build-host
echo " ============================ OG12BSTEP: host configure ================="
mkdir -p build-host
echo cd build-host
cd build-host
echo "../gcc/configure --prefix=$OG_INSTALL_DIR -v --with-pkgversion=\"AMD-OG12 Sourcery CodeBench (AMD GPU) : $GIT_ID\" --build=x86_64-pc-linux-gnu --host=x86_64-pc-linux-gnu --target=x86_64-pc-linux-gnu --enable-offload-targets=amdgcn-amdhsa=$OG_INSTALL_DIR/amdgcn-amdhsa --disable-multilib "
../gcc/configure --prefix=$OG_INSTALL_DIR -v --with-pkgversion="AMD-OG12 Sourcery CodeBench (AMD GPU) : $GIT_ID" --build=x86_64-pc-linux-gnu --host=x86_64-pc-linux-gnu --target=x86_64-pc-linux-gnu --enable-offload-targets=amdgcn-amdhsa=$OG_INSTALL_DIR/amdgcn-amdhsa --disable-multilib 2>&1 | tee ../hostconfig.stdout
if [ $? != 0 ] ; then 
   echo "ERROR configure host compiler failed"
   exit 1 
fi

echo " ============================ OG12BSTEP: host make ================="
make -j$make_jobs
if [ $? != 0 ] ; then 
   echo "ERROR  make host compiler failed"
   exit 1
fi
echo " ============================ OG12BSTEP: host install ================="
make install 
echo " ============================ OG12BSTEP: DONE ALL STEPS ================="
