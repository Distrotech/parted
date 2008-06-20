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

test_description='Make sure the scripting option works (-s) properly.'

: ${srcdir=.}
. $srcdir/test-lib.sh

# The failure messages.
cat << EOF >> errS || fail=1
Error: You requested a partition from 512B to 50.7kB.
The closest location we can manage is 17.4kB to 33.8kB.
EOF

cat << EOF >> errI || fail=1
Warning: You requested a partition from 512B to 50.7kB.
The closest location we can manage is 17.4kB to 33.8kB.
Is this still acceptable to you?
EOF
echo -n "Yes/No? " >> errI

# Test for mkpart in scripting mode
test_expect_success \
    'Create the test file' \
    'dd if=/dev/zero of=testfile bs=512 count=100 2> /dev/null'

test_expect_failure \
    'Test the scripting mode of mkpart' \
    'parted -s testfile "mklabel gpt mkpart primary ext3 1s -1s" > outS'

test_expect_success \
    'Compare the real error and the expected one' \
    '$compare outS errS'

# Test for mkpart in interactive mode.
test_expect_success \
    'Create the test file' \
    '
    rm testfile ;
    dd if=/dev/zero of=testfile bs=512 count=100 2> /dev/null
    '
test_expect_failure \
    'Test the interactive mode of mkpart' \
    'echo n | \
    parted ---pretend-input-tty testfile \
    "mklabel gpt mkpart primary ext3 1s -1s" > outI
    '
# We have to format the output before comparing.
test_expect_success \
    'normilize the output' \
    'sed -e "s,^.*Warning,Warning," -e "s,^.*Yes/No,Yes/No," -i outI'

test_expect_success \
    'Compare the real error and the expected one' \
    '$compare outI errI'

# Test for mkpartfs in scripting mode
test_expect_success \
    'Create the test file' \
    'dd if=/dev/zero of=testfile bs=512 count=100 2> /dev/null'

test_expect_failure \
    'Test the scripting mode of mkpartfs' \
    'parted -s testfile "mklabel gpt mkpartfs primary ext3 1s -1s" > outS'

test_expect_success \
    'Compare the real error and the expected one' \
    '$compare outS errS'

# Test for mkpartfs in interactive mode.
test_expect_success \
    'Create the test file' \
    '
    rm testfile ;
    dd if=/dev/zero of=testfile bs=512 count=100 2> /dev/null
    '
test_expect_failure \
    'Test the interactive mode of mkpartfs' \
    'echo n | \
    parted ---pretend-input-tty testfile \
    "mklabel gpt mkpartfs primary ext3 1s -1s" > outI
    '
# We have to format the output before comparing.
test_expect_success \
    'normilize the output' \
    'sed -e "s,^.*Warning,Warning," -e "s,^.*Yes/No,Yes/No," -i outI'

test_expect_success \
    'Compare the real error and the expected one' \
    '$compare outI errI'

test_done
