#!/bin/sh
# Exercise the exclusive, single-bit flags.

# Copyright (C) 2010 Free Software Foundation, Inc.

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

if test "$VERBOSE" = yes; then
  set -x
  parted --version
fi

: ${srcdir=.}
: ${abs_top_srcdir=$(cd .. && pwd)}
. $srcdir/t-lib.sh
ss=$sector_size_

fail=0
dev=dev-file

# Extract all msdos flag names from the texinfo documentation.
msdos_flags=$(sed -n '/^@node set/,/^@node/p' "$abs_top_srcdir/doc/parted.texi" \
  | perl -00 -ne '/^\@item (\w+).*MS-DOS/s and print lc($1), "\n"')

n_sectors=5000
dd if=/dev/null of=$dev bs=$ss seek=$n_sectors || fail=1

parted -s $dev mklabel msdos \
  mkpart pri ext2 $((1*2048))s $((2*2048-1))s \
    > out 2> err || fail=1
compare out /dev/null || fail=1

for mode in on_only on_and_off ; do
  for flag in $msdos_flags; do

    # Exclude the supplemental flags.
    # These are not boolean, like the others.
    case $flag in boot|lba|hidden) continue;; esac
    echo $flag > exp || fail=1

    # Turn on each flag, one at a time.
    parted -m -s $dev set 1 $flag on u s print > raw 2> err || fail=1
    perl -nle '/^1:2048s:4095s:2048s:::(\w+);$/ and print $1' raw > out
    compare out exp || fail=1
    compare err /dev/null || fail=1

    if test $mode = on_and_off; then
      # Turn it off
      : > exp
      parted -m -s $dev set 1 $flag off u s print > raw 2> err || fail=1
      perl -nle '/^1:2048s:4095s:2048s:::.*;$/ and print $1' raw > out
      compare err /dev/null || fail=1
    fi
  done
done

Exit $fail
