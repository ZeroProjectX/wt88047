#!/bin/bash

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#### USAGE:
#### ./buildCosmos.sh [clean]
#### [clean] - clean is optional
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#####
### Prepared by:
### Prema Chand Alugu (premaca@gmail.com)
##### Edited for adaptation to ido by rifle007
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

### This script is to compile ZPX kernel for Nougat ROMs

### This is INLINE_KERNEL_COMPILATION

####
## platform specifics
export KBUILD_BUILD_USER="Cangkuls"
export KBUILD_BUILD_HOST="ZeroProjectX"
export ARCH=arm
export SUBARCH=arm
TOOL_CHAIN_ARM=arm-eabi-
export USE_CCACHE=1

#@@@@@@@@@@@@@@@@@@@@@@ DEFINITIONS BEGIN @@@@@@@@@@@@@@@@@@@@@@@@@@@#
##### Tool-chain, you should get it yourself which tool-chain 
##### you would like to use
KERNEL_TOOLCHAIN=/root/android_prebuilts_gcc_linux-x86_arm_arm-eabi-4.9/bin/$TOOL_CHAIN_ARM

## This script should be inside the kernel-code directory
KERNEL_DIR=$PWD
DT_IMG=$KERNEL_DIR/arch/arm/boot/dt.img
DTBTOOL=$KERNEL_DIR/tools/dtbToolCM
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
## should be preset in arch/arm/configs of kernel-code
KERNEL_DEFCONFIG=wt88047_defconfig

## make jobs
MAKE_JOBS=10

## Give the path to the toolchain directory that you want kernel to compile with
## Not necessarily to be in the directory where kernel code is present
export CROSS_COMPILE=$KERNEL_TOOLCHAIN

#@@@@@@@@@@@@@@@@@@@@@@ DEFINITIONS  END  @@@@@@@@@@@@@@@@@@@@@@@@@@@#


# Use -gt 1 to consume two arguments per pass in the loop (e.g. each
# argument has a corresponding value to go with it).
# Use -gt 0 to consume one or more arguments per pass in the loop (e.g.
# some arguments don't have a corresponding value to go with it such
# as in the --default example).
# note: if this is set to -gt 0 the /etc/hosts part is not recognized ( may be a bug )
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    clean)
    CLEAN_BUILD=YES
    #shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done


#@@@@@@@@@@@@@@@@@ START @@@@@@@@@@@@@@@@@@@@#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

rm -f .version;
	echo 0 > .version;
	rm -f include/generated/compile.h

# Ask for version number
version() {
	printf "Kernel build number: ";
	read v;
  EV=EXTRAVERSION=-$v-;
  echo "$v" > .extraversion;
	
}

version2() {
	printf "ZIP Package version or name: ";
	read z;
	
}

## start ##


## copy Anykernel2 from /root

echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo " # SCRIPT COMPILER #"
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo " "
version2;
version;
echo "***** Tool chain is set to *****"
echo "$KERNEL_TOOLCHAIN"
echo ""
echo "***** Kernel defconfig is set to *****"
echo "$KERNEL_DEFCONFIG"
 make $KERNEL_DEFCONFIG
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Read [clean]
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
if [ "$CLEAN_BUILD" == 'YES' ]
        then echo;
        echo "***************************************************************"
        echo "***************!!!!!  BUILDING CLEAN  !!!!!********************"
        echo "***************************************************************"
        echo;
         make clean
         make mrproper
        make ARCH=$ARCH CROSS_COMPILE=$TOOL_CHAIN_ARM  $KERNEL_DEFCONFIG
fi


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Do the JOB, make it
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
## you can tune the job number depends on the cores
   v=`cat .extraversion`;
  EV=EXTRAVERSION=--$v-;
 make $EV -j$MAKE_JOBS

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#@@@@@@@@@@@@@@@@@@ END @@@@@@@@@@@@@@@@@@@@@#


#@@@@@@@@@@@@@@@@ AnyKernel2 @@@@@@@@@@@@@@@@@@@@@@#
# Environment variables for flashable zip creation (AnyKernel2)
ANYKERNEL=./ZPX/AnyKernel2;

##sesuaikan lokasi boot arm/arm64 dan nama zImage
KERNELPATH=arch/arm/boot;
ZIMAGE=zImage

# NOTE: Generate value for build date before creating zip in order to get accurate value
DATE=$(date +"%Y%m%d-%H%M");

#ubah nama device masing-masing (ido)
ZIP=ZPX-EXCALIBUR-$z-redmi2-$DATE.zip;

#dtb tool

./ZPX/dtbToolCM -2 -o ./arch/arm/boot/dt.img -s 2048 -p ./scripts/dtc/ ./arch/arm/boot/dts/

cp -r ./arch/arm/boot/dt.img $ANYKERNEL/dtb

# Create flashable zip
if [ -f $KERNELPATH/$ZIMAGE ]; then
echo "Create Flashable zip Anykernel2";
cp -f $KERNELPATH/$ZIMAGE $ANYKERNEL/zImage;
cd $ANYKERNEL/;
zip -qr9 $ZIP .;
cd ../..;

# The whole process is now complete. Now do some touches...
# move ZIP to /root
mv -f $ANYKERNEL/$ZIP /root/r2/$ZIP;

#Then doing cleanup
echo "Doing post-cleanup...";
rm -f $KERNELPATH/$ZIMAGE;
rm -f $ANYKERNEL/zImage;
echo "Done.";

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))


echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "                                        "
echo "     KERNEL BUILD IS SUCCESSFUL         "
echo "                                        "
echo " $ZIP                 "
echo "                                        "
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
else
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "                                        "
echo "     ERROR !!! ERROR !!! ERROR !!!      "
echo "                                        "
echo "          DON'T GIVE UP @_@             "
echo "                                        "
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
fi
exit
