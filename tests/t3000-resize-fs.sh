#!/bin/sh
# exercise the resize sub-command; FAT and HFS only

# Copyright (C) 2009 Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

if test "$VERBOSE" = yes; then
  set -x
  parted --version
fi

: ${srcdir=.}
. $srcdir/t-lib.sh

require_root_
require_scsi_debug_module_
require_512_byte_sector_size_

cat <<EOF > exp-warning || framework_failure
WARNING: you are attempting to use parted to operate on (resize) a file system.
parted's file system manipulation code is not as robust as what you'll find in
dedicated, file-system-specific packages like e2fsprogs.  We recommend
you use parted only to manipulate partition tables, whenever possible.
Support for performing most operations on most types of file systems
will be removed in an upcoming release.
EOF

ss=$sector_size_

start=63s
default_end=546147s
    new_end=530144s

# create memory-backed device
scsi_debug_setup_ dev_size_mb=550 > dev-name ||
  skip_test_ 'failed to create scsi_debug device'
dev=$(cat dev-name)

fail=0

parted -s $dev mklabel gpt > out 2>&1 || fail=1
# expect no output
compare out /dev/null || fail=1

# ensure that the disk is large enough
dev_n_sectors=$(parted -s $dev u s p|sed -n '2s/.* \([0-9]*\)s$/\1/p')
device_sectors_required=$(echo $default_end | sed 's/s$//')
# Ensure that $dev is large enough for this test
test $device_sectors_required -le $dev_n_sectors || fail=1

for fs_type in hfs+ fat32; do

  # create an empty $fs_type partition, cylinder aligned, size > 256 MB
  parted -s $dev mkpart primary $fs_type $start $default_end > out 2>&1 || fail=1
  # expect no output
  compare out /dev/null || fail=1

  # print partition table
  parted -m -s $dev u s p > out 2>&1 || fail=1

  # FIXME: check expected output

  # There's a race condition here: on udev-based systems, the partition#1
  # device, ${dev}1 (i.e., /dev/sde1) is not created immediately, and
  # without some delay, this mount command would fail.  Using a flash card
  # as $dev, the loop below typically iterates 7-20 times.

  # wait for new partition device to appear
  i=0
  while :; do
    test -e "${dev}1" && break; test $i = 90 && break;
    i=$(expr $i + 1)
    sleep .01 2>/dev/null || sleep 1
  done
  test $i = 90 && fail=1

  case $fs_type in
    fat32) mkfs_cmd='mkfs.vfat -F 32';;
    hfs*) mkfs_cmd='mkfs.hfs';;
    *) error "internal error: unhandled fs type: $fs_type";;
  esac

  # create the file system
  $mkfs_cmd ${dev}1 || fail=1

  # NOTE: shrinking is the only type of resizing that works.
  # resize that file system to be one cylinder (8MiB) smaller
  parted -s $dev resize 1 $start $new_end > out 2> err || fail=1
  # expect no output
  compare out /dev/null || fail=1
  compare err exp-warning || fail=1

  # print partition table
  parted -m -s $dev u s p > out 2>&1 || fail=1

  # compare against expected output
  sed -n 3p out > k && mv k out || fail=1
  printf "1:$start:$new_end:530082s:$fs_type:primary:$ms;\n" > exp || fail=1
  compare out exp || fail=1

  # Create a clean partition table for the next iteration.
  parted -s $dev mklabel gpt > out 2>&1 || fail=1
  # expect no output
  compare out /dev/null || fail=1

done

Exit $fail
