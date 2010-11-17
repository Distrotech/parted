#!/bin/sh

# Copyright (C) 2007-2010 Free Software Foundation, Inc.

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

test_description='run the zerolen unit tests in a directory supporting O_DIRECT'

# Need root privileges to create a device-mapper device.
privileges_required_=1
device_mapper_required_=1

: ${top_srcdir=../..}
. "$top_srcdir/tests/test-lib.sh"

init_root_dir_

# This test only makes sense on Linux.
test "$(uname -s)" = Linux \
  || skip_test_ "not on Linux"

test "x$DYNAMIC_LOADING" = xyes \
  || skip_test_ "no dynamic loading support"

test "x$ENABLE_DEVICE_MAPPER" = xyes \
  || skip_test_ "no device-mapper support"

# Device map name - should be random to not conflict with existing ones on
# the system
linear_=plinear-$$

cleanup_()
{
  # 'dmsetup remove' may fail because udev is still processing the device.
  # Try it repeatedly for 2s.
  i=0
  incr=1
  while :; do
    dmsetup remove $linear_ > /dev/null 2>&1 && break
    sleep .1 2>/dev/null || { sleep 1; incr=10; }
    i=$(expr $i + $incr); test $i = 20 && break
  done
  if test $i = 20; then
    dmsetup remove $linear_
  fi

  test -n "$d1" && losetup -d "$d1"
  rm -f "$f1"
}

f1=$(pwd)/1
d1=$(loop_setup_ "$f1") \
  || skip_test_ "is this partition mounted with 'nodev'?"

echo "0 1024 linear $d1 0" | dmsetup create "$linear_" \
  || skip_test_ "unable to create dm device"

wait_for_dev_to_appear_ "/dev/mapper/$linear_" \
  || skip_test_ "dm device did not appear"

test_expect_success \
    'run the actual tests' "zerolen /dev/mapper/$linear_"

test_done
