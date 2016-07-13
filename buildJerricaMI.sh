#!/bin/bash

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#### USAGE:
#### ./buildJerricaMI.sh [clean]
#### [clean] - clean is optional
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
#####
### Prepared by:
### Prema Chand Alugu (premaca@gmail.com)
#####
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#

### This script is to compile JERRICA kernel for MiUi7/8

### This is INLINE_KERNEL_COMPILATION

### Create a directory, and keep kernel code, example:
#### premaca@paluguUB:~/KERNEL_COMPILE$ ls
####    arm-eabi-4.8  kernel-code
####

JERRICA_POSTFIX=$(date +"%Y%m%d")

#@@@@@@@@@@@@@@@@@@@@@@ DEFINITIONS BEGIN @@@@@@@@@@@@@@@@@@@@@@@@@@@#
##### Tool-chain, you should get it yourself which tool-chain 
##### you would like to use
KERNEL_TOOLCHAIN=../arm-eabi-4.8/bin/arm-eabi-

## This script should be inside the kernel-code directory
KERNEL_DIR=$PWD

## should be preset in arch/arm/configs of kernel-code
KERNEL_DEFCONFIG=wt88047_kernel_defconfig

## boot image tools
BOOTIMG_TOOLS_PATH=$PWD/mkbootimg_tools/

## release out directory
RELEASE_DIR=$KERNEL_DIR/out/
JERRICA_MI_RELEASE=Jerrica-MI-REL4.0-$JERRICA_POSTFIX.zip

## make jobs
MAKE_JOBS=10

## extracted directory from original target boot.img (MiUi8)
BOOTIMG_EXTRACTED_DIR=$PWD/boot_miui8_extracted/

## platform specifics
export ARCH=arm
export SUBARCH=arm

## Give the path to the toolchain directory that you want kernel to compile with
## Not necessarily to be in the directory where kernel code is present
export CROSS_COMPILE=$KERNEL_TOOLCHAIN
#@@@@@@@@@@@@@@@@@@@@@@ DEFINITIONS  END  @@@@@@@@@@@@@@@@@@@@@@@@@@@#


## command execution function, which exits if some command execution failed
function exec_command {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "********************************" >&2
        echo "!! FAIL !! executing command $1" >&2
        echo "********************************" >&2
    	exit
    fi
    return $status
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Prepare out directory
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
exec_command rm -f $RELEASE_DIR/*.zip
exec_command rm -f $RELEASE_DIR/boot.img
exec_command rm -rf $RELEASE_DIR/system/lib
exec_command rm -f $KERNEL_DIR/arch/arm/boot/zImage
exec_command rm -f $KERNEL_DIR/arch/arm/boot/dt.img
exec_command rm -f  $BOOTIMG_EXTRACTED_DIR/kernel $BOOTIMG_EXTRACTED_DIR/dt.img

echo "***** Tool chain is set to $KERNEL_TOOLCHAIN *****"
echo "***** Kernel defconfig is set to $KERNEL_DEFCONFIG *****"
exec_command make $KERNEL_DEFCONFIG

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Read [clean]
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
## $1 = clean
##
cleanC=0
if [ $# -ne 0 ]; then
cleanC=1
fi

if [ $cleanC -eq 1 ]
then
echo "***** Going for Clean Compilation *****"
exec_command make clean
else
echo "***** Going for Dirty Compilation *****"
fi

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Do the JOB, make it
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
## you can tune the job number depends on the cores
exec_command make -j$MAKE_JOBS

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Generate DT.img and verify zImage/dt.img
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Generating DT.IMG *****"
exec_command $BOOTIMG_TOOLS_PATH/dtbToolCM -2 -o $KERNEL_DIR/arch/arm/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
echo "***** Verify zImage and dt.img *****"
exec_command ls $KERNEL_DIR/arch/arm/boot/zImage
exec_command ls $KERNEL_DIR/arch/arm/boot/dt.img

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# copy wlan.ko to out/system/lib/modules/pronto
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Copying wlan.ko to $RELEASE_DIR *****"
exec_command mkdir -p $RELEASE_DIR/system/lib/modules/pronto/
exec_command cp $KERNEL_DIR/drivers/staging/prima/wlan.ko $RELEASE_DIR/system/lib/modules/pronto/pronto_wlan.ko

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# copy radio-iris-transport.ko to out/system/lib/modules/
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Copying radio-iris-transport.ko to $RELEASE_DIR *****"
exec_command mkdir -p $RELEASE_DIR/system/lib/modules/
exec_command cp $KERNEL_DIR/drivers/media/radio/radio-iris-transport.ko $RELEASE_DIR/system/lib/modules/radio-iris-transport.ko

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# copy zImage and dt.img to boot_miui8_extracted
# for our boot.img preparation
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Copying zImage to $BOOTIMG_EXTRACTED_DIR/kernel *****"
echo "***** Copying dt.img to $BOOTIMG_EXTRACTED_DIR/dt.img *****"
exec_command cp $KERNEL_DIR/arch/arm/boot/zImage $BOOTIMG_EXTRACTED_DIR/kernel
exec_command cp $KERNEL_DIR/arch/arm/boot/dt.img $BOOTIMG_EXTRACTED_DIR/dt.img

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
# Generate our boot.img and verify we got it
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Moving to directory $BOOTIMG_TOOLS_PATH *****"
exec_command cd $BOOTIMG_TOOLS_PATH
echo "***** Generating boot.img into $RELEASE_DIR *****"
exec_command ./mkboot $BOOTIMG_EXTRACTED_DIR $RELEASE_DIR/boot.img
echo "***** Check the existence of boot.img in $RELEASE_DIR *****"
exec_command ls $RELEASE_DIR/boot.img

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
######## TIME FOR FINAL JOB
##
## Generate the Final Flashable Zip
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
echo "***** Verify what we got in $RELEASE_DIR *****"
exec_command ls $RELEASE_DIR
echo "***** MAKING the Final Flashable ZIP $FINAL_KERNEL_BOOT_ZIP from $RELEASE_DIR *****"
exec_command cd $RELEASE_DIR
exec_command zip -r9 $JERRICA_MI_RELEASE *

echo "***** Please Scroll up and verify for any Errors *****"
echo "***** Script exiting Successfully !! *****"

exec_command cd $KERNEL_DIR

echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "##                                                      ##"
echo "##     KERNEL BUILD IS SUCCESSFUL                       ##"
echo "##                                                      ##"
echo "##     Flash this out/$JERRICA_MI_RELEASE               ##"
echo "##                                                      ##"
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"

exit
