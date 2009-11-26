#!/bin/sh
# verify that new alignment-querying functions work

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

# check for scsi_debug module
modprobe -n scsi_debug ||
  skip_test_ "you lack the scsi_debug kernel module"

grep '^#define USE_BLKID 1' "$CONFIG_HEADER" > /dev/null ||
  skip_test_ 'this system lacks a new-enough libblkid'

cat <<EOF > exp || framework_failure
minimum: 7 8
optimal: 7 64
partition alignment: 0 1
EOF

# create memory-backed device
scsi_debug_setup_ physblk_exp=3 lowest_aligned=7 num_parts=4 > dev-name ||
  skip_test_ 'failed to create scsi_debug device'
scsi_dev=$(cat dev-name)

fail=0

# print alignment info
"$abs_srcdir/print-align" $scsi_dev > out 2>&1 || fail=1

compare out exp || fail=1

Exit $fail
