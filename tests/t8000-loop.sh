#!/bin/sh
# Test usage of loop devices

# Copyright (C) 2008-2009 Free Software Foundation, Inc.

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
lvm_init_root_dir_

d1=
cleanup_()
{
  test -n "$d1" && losetup -d "$d1"
  rm -f "$f1";
}

f1=$(pwd)/1; d1=$(loop_setup_ "$f1") \
  || skip_test_ "is this partition mounted with 'nodev'?"

printf '%s\n' \
    'Warning: WARNING: the kernel failed to re-read the partition table on' \
  > exp || framework_failure

fail=0

# Expect this to exit with status of 1.
parted -s $d1 mklabel msdos > err 2>&1
test $? = 1 || fail=1
sed 's/^\(Warn.*table on\).*/\1/' err > k && mv k err || fail=1

compare exp err || fail=1

# Create a partition; expect to exit 1
parted -s $d1 mkpart primary 1 10 > err 2>&1
test $? = 1 || fail=1
sed 's/^\(Warn.*table on\).*/\1/' err > k && mv k err || fail=1

# check for expected output
compare exp err || fail=1

Exit $fail
