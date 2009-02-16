#!/bin/sh

# Copyright (C) 2008 Free Software Foundation, Inc.

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

test_description='Test usage of loop devices'

privileges_required_=1
device_mapper_required_=1

: ${srcdir=.}
. $srcdir/test-lib.sh

cleanup_() {
    test -n "$d1" && losetup -d "$d1"
    rm -f "$f1";
}

emit_expected_diagnostic()
{
    printf '%s\n' \
      'Error: Error informing the kernel about modifications to partiti' \
      'Warning: The kernel was unable to re-read the partition table on'
}

test_expect_success \
    "setup: create loop devices" \
    'f1=$(pwd)/1 && d1=$(loop_setup_ "$f1")'

test_expect_success \
    'run parted -s "$d1" mklabel msdos' \
    'parted -s $d1 mklabel msdos > out 2>&1'
test_expect_success 'check for empty output' 'compare out /dev/null'

test_expect_failure \
    'run parted -s "$d1" mkpart primary 1 10' \
    'parted -s $d1 mkpart primary 1 10 > out 2>&1'
test_expect_success 'prepare actual/expected output' \
    'emit_expected_diagnostic > exp &&
     cut -b1-64 out > k && mv k out'
test_expect_success 'check for expected output' 'compare exp out'

test_done
