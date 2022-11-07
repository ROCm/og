#!/bin/bash
#
# link_short_names.sh:  
#     If gcc build creates binary names with a long prefix name,
#     this script creates a symbolic link from a short name 
#     to the long name so name like g++ and gfortran work.
#
OGDIR=${OGDIR:-/opt/og12}
OGVER=${OGVER:-sourcery-2022.09-5}
dirname=${1:-$OGDIR/$OGVER/bin}
[ ! -d $dirname ] && echo $dirname not found && exit 1
prefix="x86_64-none-linux-gnu-"
echo cd $dirname
cd $dirname
for n in `ls $dirname` ; do 
   [ ${n:0:22} == $prefix ] && echo ln -sf $n ${n#*$prefix}
   [ ${n:0:22} == $prefix ] && ln -sf $n ${n#*$prefix}
   # [ ${n:0:22} == $prefix ] && rm ${n#*$prefix}
done
