#!/bin/bash

function usage(){
  echo ""
  echo "---------------- Usage ----------------"
  echo "./run_umt.sh [option]"
  echo "Options:  build_mpi, build_umt, run_umt"
  echo "---------------------------------------"
  echo ""
}

export ROCM_PATH=/opt/rocm

export OG=$HOME/git/og12/install
#export OG=/opt/og12/sourcery-2022.09-7

if [[ "$OG" == *"sourcery"* ]]; then
    OGCC=$OG/bin/x86_64-none-linux-gnu-gcc 
    OGCXX=$OG/bin/x86_64-none-linux-gnu-c++ 
    OGFC=$OG/bin/x86_64-none-linux-gnu-gfortran
    export OGLIBDIR=$OG/x86_64-none-linux-gnu/
else
    OGCC=$OG/bin/x86_64-pc-linux-gnu-gcc 
    OGCXX=$OG/bin/x86_64-pc-linux-gnu-c++ 
    OGFC=$OG/bin/x86_64-pc-linux-gnu-gfortran
    export OGLIBDIR=$OG
fi

export UMT_PATH=$HOME/git/og-test/UMT2013-20140204

export OMPI_PATH=$HOME/git/ompi
export MPI_INSTALL_DIR=$HOME/local/ompi

export PATH=$OG/bin:$PATH
export LD_LIBRARY_PATH=$OGLIBDIR/lib64:$ROCM_PATH/hsa/lib:$LD_LIBRARY_PATH

# Build MPI
if [ "$1" == "build_mpi" ]; then

    if [ ! -d "$OMPI_PATH" ]; then
        echo "$OMPI_PATH does not exists. Cloning OMPI"
        git clone --recursive  https://github.com/open-mpi/ompi.git $OMPI_PATH
    fi

    pushd $OMPI_PATH
    ./autogen.pl
    ./configure --prefix=$MPI_INSTALL_DIR CC=$OGCC CXX=$OGCXX FC=$OGFC OMPI_CC=$OGCC OMPI_CXX=$OGCXX OMPI_FC=$OGFC
    make && make install
    popd
    exit 1
fi

export PATH=$MPI_INSTALL_DIR/bin:$PATH
export LD_LIBRARY_PATH=$MPI_INSTALL_DIR/lib:$LD_LIBRARY_PATH

# Build UMT
if [ "$1" == "build_umt" ]; then

    if [ ! -d "$MPI_INSTALL_DIR" ]; then
        echo "*******************************************************************************"
        echo "You need to build MPI first. Run the script with the build_mpi option to do so."
        echo "*******************************************************************************"
        exit 0;
    fi


if [ -f "$UMT_PATH/make.defs" ]; then
    mv $UMT_PATH/make.defs $UMT_PATH/make.defs.backup
fi

cp -r ./make.defs.umt $UMT_PATH/make.defs
pushd $UMT_PATH

echo "*** Building UMT ***"
make 
pushd $UMT_PATH/Teton
make SuOlsonTest
popd

if [ -f "$UMT_PATH/make.defs.backup" ]; then
    mv $UMT_PATH/make.defs.backup $UMT_PATH/make.defs
fi

popd
exit 1
fi

# Run UMT
if [ "$1" == "run_umt" ]; then
    pushd $UMT_PATH/Teton
    mpirun -np 64 ./SuOlsonTest grid_64MPI_12x12x12.cmg 16 2 16 8 4
    popd
    exit 1
fi

usage