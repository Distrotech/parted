#!/bin/sh

# Copyright (C) 2007-2010 Free Software Foundation, Inc.

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

test_description='run the /dev/mapper symlink test'

# Need root privileges to create a symlink under /dev/mapper.
privileges_required_=1

: ${top_srcdir=../..}
. "$top_srcdir/tests/test-lib.sh"

test_expect_success \
    'run the actual tests' 'symlink'

test_done
