#!/bin/sh
# Copyright 2005-2016 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities granted to it by
# virtue of its status as an intergovernmental organisation nor does it submit to any jurisdiction.
#

. ./include.sh

#Define a common label for all the tmp files
label="bufr_dump_fortran_test"

#Create log file
fLog=${label}".log"
rm -f $fLog

#Define temp files
tempBufr=outfile.bufr
tempSrc=$label.temp.f90
tempExe=$label.temp.exe

bufr_files=`cat ${data_dir}/bufr/bufr_data_files.txt`

# If FORTRAN is enabled, then the pkgconfig should be one level above the test dir
PKGCONFIG_FILE=../eccodes_f90.pc
CACHE_FILE=../CMakeCache.txt

# Work out the Fortran compiler, the flags etc from pkgconfig
COMPILE_AND_RUN=0

if command -v pkg-config >/dev/null 2>&1; then
  if [ -f "$PKGCONFIG_FILE" ]; then
    COMPILER=`pkg-config --variable=FC $PKGCONFIG_FILE`
    FLAGS_COMPILER=`pkg-config --cflags $PKGCONFIG_FILE`
    FLAGS_LINKER=`pkg-config --libs $PKGCONFIG_FILE`

    # The pkgconfig variables refer to the install directory. Change to build dir
    BUILD_DIR=`grep -w eccodes_BINARY_DIR $CACHE_FILE | cut -d'=' -f2`
    INSTALL_DIR=`grep -w CMAKE_INSTALL_PREFIX $CACHE_FILE | cut -d'=' -f2`
    FLAGS_LINKER=`echo $FLAGS_LINKER | sed -e "s:$INSTALL_DIR:$BUILD_DIR:g"`
    FLAGS_COMPILER=`echo $FLAGS_COMPILER | sed -e "s:$INSTALL_DIR:$BUILD_DIR:g"`

    # TODO: For now only support when shared libs enabled
    SHARED_LIBS=`grep -w BUILD_SHARED_LIBS $CACHE_FILE | cut -d'=' -f2`
    if [ "$SHARED_LIBS" = "ON" ]; then
      COMPILE_AND_RUN=1
    fi
  fi
fi

for file in ${bufr_files}
do
  # Generate F90 code from BUFR file
  ${tools_dir}bufr_dump -Efortran ${data_dir}/bufr/$file > $tempSrc
  
  # Compile
  if [ $COMPILE_AND_RUN -eq 1 ]; then
    $COMPILER -o $tempExe $tempSrc $FLAGS_COMPILER $FLAGS_LINKER
    # The executable always creates a file called outfile.bufr
    ./$tempExe
    ${tools_dir}bufr_compare ${data_dir}/bufr/$file $tempBufr

    ${tools_dir}bufr_dump -jf ${data_dir}/bufr/$file > $file.json
    ${tools_dir}bufr_dump -jf $tempBufr              > $tempBufr.json
    #diff $file.json $tempBufr.json
    rm -f $file.json $tempBufr.json
  fi
done

rm -f $tempSrc $tempExe $tempBufr