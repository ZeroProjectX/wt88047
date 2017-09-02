#!/sbin/sh

# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# EDIFY properties
kernel.string=rifle007 @xda
do.devicecheck=0
do.initd=1
do.modules=0
do.cleanup=1
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=

# shell variables
#leave blank for automatic search boot block
#block=
#is_slot_device=0;

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;

## AnyKernel permissions
# set permissions for included ramdisk files
mount /system;
mount -o remount,rw /system;
chmod -R 755 $ramdisk
cp -rpf $patch/init.d /system/etc
cp -rpf $patch/cron.d /system/etc
chmod -R 755 /system/etc/init.d
chmod -R 755 /system/etc/cron.d
#rm /system/etc/init.d/99zpx_zram
#mv /system/bin/vm_bms /system/bin/vm_bms.bak
#chmod 644 $ramdisk/sbin/media_profiles.xml

## AnyKernel install
find_boot;
dump_boot;

# begin ramdisk changes

#change minfreq buildprop
sed -i '/ro.min_freq_0/d' /system/build.prop
sed -i '/^$/d' /system/build.prop
echo "ro.min_freq_0=302400" >> /system/build.prop

replace_line fstab.qcom "/dev/block/zram0" "/dev/block/zram0                              none        swap            defaults             zramsize=1073741824,notrim";

# init.qcom.rc
#insert_line init.qcom.rc "init.spectrum.rc" after "import init.target.rc" "import /init.spectrum.rc"

## init.tuna.rc
#backup_file init.tuna.rc;
#insert_line init.tuna.rc "nodiratime barrier=0" after "mount_all /fstab.tuna" "\tmount ext4 /dev/block/platform/omap/omap_hsmmc.0/by-name/userdata /data remount nosuid nodev noatime nodiratime barrier=0";
#append_file init.tuna.rc "dvbootscript" init.tuna;

## init.superuser.rc
#if [ -f init.superuser.rc ]; then
#  backup_file init.superuser.rc;
#  replace_string init.superuser.rc "Superuser su_daemon" "# su daemon" "\n# Superuser su_daemon";
#  prepend_file init.superuser.rc "SuperSU daemonsu" init.superuser;
#else
#  replace_file init.superuser.rc 750 init.superuser.rc;
#  insert_line init.rc "init.superuser.rc" after "on post-fs-data" "    #import /init.superuser.rc";
#fi;

## insert extra init file init.mk.rc , init.aicp.rc , init.cm.rc
#backup_file init.rc
#insert_line init.rc "init.mk.rc" after "extra init file" "import /init.mk.rc";
#insert_line init.rc "init.aicp.rc" after "extra init file" "import /init.aicp.rc";
#insert_line init.rc "init.cm.rc" after "extra init file" "import /init.cm.rc";

## fstab.tuna
#backup_file fstab.tuna;
#patch_fstab fstab.tuna /system ext4 options "nodiratime,barrier=0" "nodev,noatime,nodiratime,barrier=0,data=writeback,noauto_da_alloc,discard";
#patch_fstab fstab.tuna /cache ext4 options "barrier=0,nomblk_io_submit" "nosuid,nodev,noatime,nodiratime,errors=panic,barrier=0,nomblk_io_submit,data=writeback,noauto_da_alloc";
#patch_fstab fstab.tuna /data ext4 options "nomblk_io_submit,data=writeback" "nosuid,nodev,noatime,errors=panic,nomblk_io_submit,data=writeback,noauto_da_alloc";
#append_file fstab.tuna "usbdisk" fstab;

## make permissive
cmdtmp=`cat $split_img/*-cmdline`;
        if [[ "$cmdtmp" != *selinux=permissive* ]]; then
          echo "androidboot.selinux=permissive $cmdtmp" > $split_img/*-cmdline;
        fi;

## end ramdisk changes

write_boot;

## end install
