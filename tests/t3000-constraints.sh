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

test_description="exercise Parted's constraint-management code"

. ./init.sh

dev=loop-file
N=2
t=ext2

test_expect_success \
    "setup: label and create a small $t partition" \
    'dd if=/dev/null of=$dev bs=1 seek=${N}M 2>/dev/null &&
     { echo y; echo c; } > in &&
     { emit_superuser_warning
       echo "Warning: You requested a partition from 1000kB to 2000kB."
       echo "The closest location we can manage is 15.9kB to 15.9kB." \
	    " Is this still acceptable to you?"
       echo "Yes/No? y"
       echo "Error: File system too small for ext2."; } > exp &&
     parted -s $dev mklabel msdos &&
     parted -s $dev mkpartfs primary $t 1 $N'

# Before parted-1.9, this would fail with a buffer overrun
# leading to a segfault.
test_expect_failure \
    'try to create another partition in the same place' \
    'parted ---pretend-input-tty $dev mkpartfs primary $t 1 $N <in >out 2>&1'

test_expect_success \
    'normalize the actual output' \
    'sed "s,   *,,;s, $,," out > o2 && mv -f o2 out'

test_expect_success 'check for expected output' '$compare out exp'

test_done
