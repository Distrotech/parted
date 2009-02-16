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
cat << EOF > errS || fail=1
Error: You requested a partition from 512B to 50.7kB.
The closest location we can manage is 17.4kB to 33.8kB.
EOF

{ emit_superuser_warning
  sed s/Error/Warning/ errS
  printf 'Is this still acceptable to you?\nYes/No?'; } >> errI || fail=1

for mkpart in mkpart mkpartfs; do

  # Test for mkpart/mkpartfs in scripting mode
  test_expect_success \
      'Create the test file' \
      'dd if=/dev/zero of=testfile bs=512 count=100 2> /dev/null'

  test_expect_failure \
      "Test the scripting mode of $mkpart" \
      'parted -s testfile -- mklabel gpt '$mkpart' primary ext3 1s -1s > out'

  test_expect_success \
      'Compare the real error and the expected one' \
      'compare out errS'

  # Test mkpart/mkpartfsin interactive mode.
  test_expect_success \
      'Create the test file' \
      '
      rm testfile ;
      dd if=/dev/zero of=testfile bs=512 count=100 2> /dev/null
      '
  test_expect_failure \
      "Test the interactive mode of $mkpart" \
      'echo n | \
      parted ---pretend-input-tty testfile \
      "mklabel gpt '$mkpart' primary ext3 1s -1s" > out
      '
  # We have to format the output before comparing.
  test_expect_success \
      'normalize the actual output' \
      'sed "s,   *,,;s, $,," out > o2 && mv -f o2 out'

  test_expect_success \
      'Compare the real error and the expected one' \
      'compare out errI'

done
test_done
