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

test_description='determine type of devicemaps.'

privileges_required_=1
device_mapper_required_=1

: ${srcdir=.}
. $srcdir/test-lib.sh

test "x$ENABLE_DEVICE_MAPPER" = xyes ||
  {
    say "skipping $0: no device-mapper support"
    test_done
    exit
  }

# Device maps names - should be random to not conflict with existing ones on
# the system
linear_=plinear
mpath_=mpath

cleanup_() {
    dmsetup remove $linear_
    dmsetup remove $mpath_
    test -n "$d1" && losetup -d "$d1"
    test -n "$d2" && losetup -d "$d2"
    test -n "$d3" && losetup -d "$d3"
    rm -f "$f1" "$f2" "$f3";
}

test_expect_success \
    "setup: create loop devices" \
    'f1=$(pwd)/1 && d1=$(loop_setup_ "$f1") && \
     f2=$(pwd)/2 && d2=$(loop_setup_ "$f2") && \
     f3=$(pwd)/3 && d3=$(loop_setup_ "$f3")'

#
# Linear Map
#

test_expect_success \
    "setup: create a linear mapping" \
    'echo 0 1024 linear "$d1" 0 | dmsetup create "$linear_" &&
     dev="$DM_DEV_DIR"/mapper/"$linear_"'

test_expect_success \
    'run parted -s "$dev" mklabel msdos' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'check for empty output' 'compare out /dev/null'

test_expect_success \
    "determine the map type" \
    'parted -s "$dev" print > out 2>&1'

# Create expected output file.
fail=0
{ emit_superuser_warning > exp; } || fail=1
cat <<EOF >> exp || fail=1
Model: Linux device-mapper (linear) (dm)
Disk $dev: 524kB
Sector size (logical/physical): 512B/512B
Partition Table: msdos

Number  Start  End  Size  Type  File system  Flags

EOF
test_expect_success \
    'create expected output file' \
    'test $fail = 0'

test_expect_success \
    'check its output' \
    'compare out exp'

#
# Multipath Map
#

test_expect_success \
    "setup: create a multipath mapping" \
    'echo 0 1024 multipath 0 0 1 1 round-robin 0 2 0 "$d2" "$d3" \
            | dmsetup create "$mpath_" &&
     dev="$DM_DEV_DIR"/mapper/"$mpath_"'

test_expect_success \
    'run parted -s "$dev" mklabel msdos' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'check for empty output' 'compare out /dev/null'

test_expect_success \
    "determine the map type" \
    'parted -s "$dev" print > out 2>&1'

# Create expected output file.
fail=0
{ emit_superuser_warning > exp; } || fail=1
cat <<EOF >> exp || fail=1
Model: Linux device-mapper (multipath) (dm)
Disk $dev: 524kB
Sector size (logical/physical): 512B/512B
Partition Table: msdos

Number  Start  End  Size  Type  File system  Flags

EOF
test_expect_success \
    'create expected output file' \
    'test $fail = 0'

test_expect_success \
    'check its output' \
    'compare out exp'

test_done
