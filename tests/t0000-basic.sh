#!/bin/sh
# Ensure that a simple command using -s succeeds with no prompt

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

../parted/parted --version > /dev/null 2>&1
if test $? != 0; then
  echo >&2 'You have not built parted yet.'
  exit 1
fi

test_description='Test the very basics part #1.'

. ./init.sh

# FIXME: is id -u portable enough?
uid=`id -u` || uid=1

# create a file of size N bytes
N=1M
dev=loop-file

test_expect_success \
    'create the test file' \
    'dd if=/dev/null of=$dev bs=1 seek=$N 2> /dev/null'

test_expect_success \
    'run parted -s FILE mklabel msdos' \
    'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'expect no output' '$compare out /dev/null'

# ----------------------------------------------
# Now, ensure that a simple mklabel command succeeds.
# Since there's no -s option, there are prompts -- sometimes.

test_expect_success \
    'erase the left-over label' \
    'dd if=/dev/zero of=$dev bs=4K count=1 2> /dev/null'

# First iteration works with no prompting, since there is no preexisting label.
test_expect_success \
    'run parted mklabel (without -s) on a blank disk' \
    'parted $dev mklabel msdos > out 2>&1'

test_expect_success \
    'create expected output file' \
    'emit_superuser_warning > exp'

test_expect_success \
    'check its "interactive" output' \
    '$compare out exp 1>&2'

test_expect_success 'create interactive input' 'printf "y\n\n" > in'

# Now that there's a label, rerunning the same command is interactive.
test_expect_success \
    'rerun that same command, but now with a preexisting label' \
    'parted ---pretend-input-tty $dev mklabel msdos < in > out 2>&1'

# Transform the actual output, to avoid spurious differences when
# $PWD contains a symlink-to-dir.  Also, remove the ^M      ...^M bogosity.
test_expect_success \
    'normalize the actual output' \
    'mv out o2 && sed -e "s,on /.*/$dev,on DEVICE,;s,   *,,;s, $,," \
                      -e "s,^.*/lt-parted: ,parted: ," o2 > out'

# Create expected output file.
fail=0
{ emit_superuser_warning > exp; } || fail=1
cat <<EOF >> exp || fail=1
Warning: The existing disk label on DEVICE will be destroyed and all\
 data on this disk will be lost. Do you want to continue?
parted: invalid token: msdos
Yes/No? y
New disk label type?  [msdos]?
EOF
test_expect_success \
    'create expected output file' \
    'test $fail = 0'

test_expect_success \
    'check its output -- slightly different here, due to prompts' \
    '$compare out exp'

test_done
