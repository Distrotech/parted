#!/bin/sh

# Copyright (C) 2007 Free Software Foundation, Inc.

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

test_description='partitioning (parted -s DEV mklabel) a busy disk must fail.'

privileges_required_=1
erasable_device_required_=1

. ./init.sh
dev=$DEVICE_TO_ERASE

test_expect_success \
    "setup: create a fat32 file system on $dev" \
    'dd if=/dev/zero "of=$dev" bs=1k count=1 2> /dev/null &&
     parted -s "$dev" mklabel msdos                > out 2>&1 &&
     parted -s "$dev" mkpartfs primary fat32 1 40 >> out 2>&1'
test_expect_success 'expect no output' '$compare out /dev/null'

mount_point="`pwd`/mnt"

# Be sure to unmount upon interrupt, failure, etc.
cleanup_() { umount "${dev}1" > /dev/null 2>&1; }

# There's a race condition here: on udev-based systems, the partition#1
# device, ${dev}1 (i.e., /dev/sdd1) is not created immediately, and
# without some delay, this mount command would fail.  Using a flash card
# as $dev, the loop below typically iterates 7-20 times.
test_expect_success \
    'create mount point dir. and mount the just-created partition on it' \
    'mkdir $mount_point &&
     i=0; while :; do test -e "${dev}1" && break; test $i = 90 && break;
	              i=$(expr $i + 1); done;
     mount "${dev}1" $mount_point'

test_expect_failure \
    'now that a partition is mounted, mklabel attempt must fail' \
    'parted -s "$dev" mklabel msdos > out 2>&1'
test_expect_success \
    'create expected output file' \
    'echo "Error: Partition(s) on $dev are being used." > exp'
test_expect_success \
    'check for expected failure diagnostic' \
    '$compare out exp'

# ==================================================
# Now, test it in interactive mode.
test_expect_success 'create input file' 'echo c > in'
test_expect_failure \
    'as above, this mklabel attempt must fail' \
    'parted ---pretend-input-tty "$dev" mklabel msdos < in > out 2>&1'

fail=0
cat <<EOF > exp || fail=1
Warning: Partition(s) on $dev are being used.
parted: invalid token: msdos
Ignore/Cancel? c
EOF
test_expect_success 'create expected output file' 'test $fail = 0'

# Transform the actual output, removing ^M   ...^M.
test_expect_success \
    'normalize the actual output' \
    'mv out o2 && sed -e "s,   *,,;s, $,," \
                      -e "s,^.*/lt-parted: ,parted: ," o2 > out'

test_expect_success \
    'check for expected failure diagnostic' \
    '$compare out exp'

test_done
