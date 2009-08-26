#!/bin/sh

# Copyright (C) 2009 Free Software Foundation, Inc.

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

test_description='Ensure parted preserves bootcode in extended partition.'

: ${srcdir=.}
. $srcdir/test-lib.sh

require_512_byte_sector_size_

dev=loop-file
bootcode_size=446

test_expect_success \
  'Create the test file' \
  'dd if=/dev/zero of=$dev bs=1024c count=100 >/dev/null 2>&1'

test_expect_success \
  'Create msdos label' \
  'parted -s $dev mklabel msdos > out 2>&1'
test_expect_success 'Expect no output' 'compare out /dev/null'

test_expect_success \
  'Create extended partition' \
  'parted -s $dev mkpart extended 32s 127s > out 2>&1'
test_expect_success 'Expect no output' 'compare out /dev/null'

test_expect_success \
  'Create logical partition' \
  'parted -s $dev mkpart logical 64s 127s > out 2>&1'
test_expect_success 'Expect no output' 'compare out /dev/null'

test_expect_success \
  'Install fake bootcode' \
  'printf %0${bootcode_size}d 0 > in &&
   dd if=in of=$dev bs=1c seek=16384 count=$bootcode_size \
      conv=notrunc > /dev/null 2>&1'

test_expect_success \
  'Save fake bootcode for later comparison' \
  'dd if=$dev of=before bs=1 skip=16384 count=$bootcode_size > /dev/null 2>&1'

test_expect_success \
  'Do something to the label' \
  'parted -s $dev rm 5 > out 2>&1'
test_expect_success 'Expect no output' 'compare out /dev/null'

test_expect_success \
  'Extract the bootcode for comparison' \
  'dd if=$dev of=after bs=1 skip=16384 count=$bootcode_size > /dev/null 2>&1'

test_expect_success \
  'Expect bootcode has not changed' \
  'compare before after'

test_done
