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

d1= f1=
cleanup_()
{
  test -n "$d1" && losetup -d "$d1"
  rm -f "$f1"
}

f1=$(pwd)/1; d1=$(loop_setup_ "$f1") \
  || skip_test_ "is this partition mounted with 'nodev'?"

fail=0

# Expect this to succeed.
parted -s $d1 mklabel msdos > err 2>&1 || fail=1
compare err /dev/null || fail=1     # expect no output

# Create a partition
parted -s $d1 mkpart primary 1 10 > err 2>&1 || fail=1
compare err /dev/null || fail=1     # expect no output

Exit $fail
