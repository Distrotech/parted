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

test_description="very basic GPT table"

: ${srcdir=.}
. $srcdir/test-lib.sh

dev=loop-file

nb=512
n_sectors=$(expr $nb '*' 512 / $sector_size_)

test_expect_success \
    "setup: create zeroed device" \
    'dd if=/dev/zero bs=512 count=$nb of=$dev'

test_expect_success \
    'create gpt label' \
    'parted -s $dev mklabel gpt > empty 2>&1'

test_expect_success 'ensure there was no output' \
    'compare /dev/null empty'

test_expect_success \
    'print the empty table' \
    'parted -m -s $dev unit s print > t 2>&1 &&
     sed 's,.*/$dev:,$dev:,' t > out'

test_expect_success \
    'check for expected output' \
    'printf "BYT;\n$dev:${n_sectors}s:file:$sector_size_:$sector_size_:gpt:;\n"\
       > exp &&
     compare exp out'

test_done
