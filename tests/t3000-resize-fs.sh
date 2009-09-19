#!/bin/sh

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

test_description='exercise the resize sub-command; FAT and HFS only'

: ${srcdir=.}
. $srcdir/test-lib.sh

require_512_byte_sector_size_
dev=$DEVICE_TO_ERASE
sz=$DEVICE_TO_ERASE_SIZE
ss=$sector_size_

start=63s
default_end=546147s
    new_end=530144s

# ensure that the disk is large enough
dev_n_sectors=$(parted -s $dev u s p|sed -n '2s/.* \([0-9]*\)s$/\1/p')
device_sectors_required=$(echo $default_end | sed 's/s$//')
test_expect_success \
  "whether $dev is large enough for this test" \
  'test $device_sectors_required -le $dev_n_sectors'

for fs_type in hfs+ fat32; do

  test_expect_success \
      'create a partition table' \
      'parted -s $dev mklabel gpt > out 2>&1'
  test_expect_success 'expect no output' 'compare out /dev/null'

  test_expect_success \
      "create an empty $fs_type partition, cylinder aligned, size > 256 MB" \
      'parted -s $dev mkpart primary $fs_type $start $default_end > out 2>&1'
  test_expect_success 'expect no output' 'compare out /dev/null'

  test_expect_success \
      'print partition table' \
      'parted -m -s $dev u s p > out 2>&1'

  # FIXME: check expected output

  # There's a race condition here: on udev-based systems, the partition#1
  # device, ${dev}1 (i.e., /dev/sde1) is not created immediately, and
  # without some delay, this mount command would fail.  Using a flash card
  # as $dev, the loop below typically iterates 7-20 times.
  test_expect_success \
      'wait for new partition device to appear' \
      'i=0; while :; do
	      test -e "${dev}1" && break; test $i = 90 && break;
	      i=$(expr $i + 1); done; test $i != 90'

  case $fs_type in
    fat32) mkfs_cmd='mkfs.vfat -F 32';;
    hfs*) mkfs_cmd='mkfs.hfs';;
    *) error "internal error: unhandled fs type: $fs_type";;
  esac

  test_expect_success \
      'create the file system' \
      '$mkfs_cmd ${dev}1'

  # NOTE: shrinking is the only type of resizing that works.
  test_expect_success \
      'resize that file system to be one cylinder (8MiB) smaller' \
      'parted -s $dev resize 1 $start $new_end > out 2>&1'
  test_expect_success 'expect no output' 'compare out /dev/null'

  test_expect_success \
      'print partition table' \
      'parted -m -s $dev u s p > out 2>&1'

  test_expect_success \
      'compare against expected output' \
      'sed -n 3p out > k && mv k out &&
       printf "1:$start:$new_end:530082s:$fs_type:primary:$ms;\n" > exp &&
       compare out exp'

done

test_done
