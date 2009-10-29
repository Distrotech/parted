#!/bin/sh

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

test_description='Make sure the scripting option works (-s) properly.'

: ${srcdir=.}
. $srcdir/test-lib.sh
ss=$sector_size_
N=100 # number of sectors

: ${abs_top_builddir=$(cd ../..; pwd)}
: ${CONFIG_HEADER="$abs_top_builddir/lib/config.h"}

config_h=$abs_top_srcdir
grep '^#define HAVE_LIBREADLINE 1' $CONFIG_HEADER > /dev/null ||
  {
    say "skipping $0: configured without readline support"
    test_done
    exit
  }

fail=0

# The failure messages.
cat << EOF > errS || fail=1
Error: You requested a partition from 512B to 50.7kB.
The closest location we can manage is 17.4kB to 33.8kB.
EOF

normalize_part_diag_ errS || fail=1

{ emit_superuser_warning
  sed s/Error/Warning/ errS
  printf 'Is this still acceptable to you?\nYes/No?'; } >> errI || fail=1

for mkpart in mkpart; do

  # Test for mkpart in scripting mode
  test_expect_success \
      'Create the test file' \
      'dd if=/dev/zero of=testfile bs=${ss}c count=$N 2> /dev/null'

  test_expect_failure \
      "Test the scripting mode of $mkpart" \
      'parted -s testfile -- mklabel gpt '$mkpart' primary ext3 1s -1s > out'

  test_expect_success \
      'Compare the real error and the expected one' \
      '
       normalize_part_diag_ out &&
       compare out errS
      '

  # Test mkpart interactive mode.
  test_expect_success \
      'Create the test file' \
      '
      rm -f testfile
      dd if=/dev/zero of=testfile bs=${ss}c count=$N 2> /dev/null
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
      '
       printf x >> out &&
       sed "s,   *,,;s, x$,,;/ n$/ {N;s, n\nx,,}" out > o2 && mv -f o2 out &&
       normalize_part_diag_ out
      '

  test_expect_success \
      'Compare the real error and the expected one' \
      'compare out errI'

done
test_done
