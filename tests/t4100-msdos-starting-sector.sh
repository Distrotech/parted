#!/bin/sh

# Copyright (C) 2008, 2009 Free Software Foundation, Inc.

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

test_description='Consistency in msdos free space starting sector.'

: ${srcdir=.}
. $srcdir/test-lib.sh

######################################################################
# parted 1.8.8.1 and earlier was inconsistent when calculating the
# start sector for free space in msdos type lables.  parted was not
# consistent in the use of metadata padding for msdos labels.
######################################################################

N=100
dev=loop-file
test_expect_success \
    'create a file to simulate the underlying device' \
    'dd if=/dev/zero of=$dev bs=1K count=$N 2> /dev/null'

test_expect_success \
    'label the test disk' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'expect no output' 'compare out /dev/null'

# Test the output of print free with no partitions.
fail=0
cat <<EOF > exp || fail=1
BYT;
path:200s:file:512:512:msdos:;
1:32s:127s:96s:free;
EOF

test_expect_success 'create expected output file' 'test $fail = 0'

test_expect_success \
    'display output of label without partitions' \
    'parted -m -s $dev unit s print free > out 2>&1'

test_expect_success \
    'check for expected output' \
    'sed "2s/^[^:]*:/path:/" < out > k; mv k out
    compare out exp'

# Test the output of print free with one partition.
fail=0
cat <<EOF > exp || fail=1
BYT;
path:200s:file:512:512:msdos:;
1:32s:96s:65s:free;
1:97s:195s:99s:::;
EOF

test_expect_success 'create expected output file' 'test $fail = 0'

test_expect_success \
    'create a partition at the end of the label' \
    'parted -s $dev mkpart primary 50K 100K'

test_expect_success \
    'display output of label with partition' \
    'parted -m -s $dev unit s print free > out 2>&1'

test_expect_success \
    'check for expected output' \
    'sed "2s/^[^:]*:/path:/" < out > k; mv k out
    compare out exp'

test_done
