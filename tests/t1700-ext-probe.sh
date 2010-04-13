#!/bin/sh
# Probe Ext2, Ext3 and Ext4 file systems

# Copyright (C) 2008-2010 Free Software Foundation, Inc.

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
require_512_byte_sector_size_

dev=loop-file
ss=$sector_size_
n_sectors=8000

fail=0

for type in ext2 ext3 ext4; do

  ( mkfs.$type -V ) >/dev/null 2>&1 || skip_test_ "no $type support"

  # create an $type file system
  dd if=/dev/zero of=$dev bs=1024 count=4096 >/dev/null || fail=1
  mkfs.$type -F $dev >/dev/null || fail=1

  # probe the $type file system
  parted -m -s $dev u s print >out 2>&1 || fail=1
  grep '^1:.*:'$type'::;$' out || fail=1

done

# Some features should indicate ext4 by themselves.
for feature in uninit_bg flex_bg; do
  # create an ext3 file system
  dd if=/dev/zero of=$dev bs=1024 count=4096 >/dev/null || fail=1
  mkfs.ext3 -F $dev >/dev/null || fail=1

  # set the feature
  tune2fs -O $feature $dev || fail=1

  # probe the file system, which should now be ext4
  parted -m -s $dev u s print >out 2>&1 || fail=1
  grep '^1:.*:ext4::;$' out || fail=1
done

Exit $fail
