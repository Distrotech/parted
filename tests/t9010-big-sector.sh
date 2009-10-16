#!/bin/sh
# check physical sector size as reported by 'print'

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

if test "$VERBOSE" = yes; then
  set -x
  parted --version
fi

: ${srcdir=.}
. $srcdir/t-lib.sh

require_root_

dev=
cleanup_() {
  # Remove the module only if this script added it.
  test -z "$dev" && return

  # We have to insist.  Otherwise, a single rmmod usually fails to remove it.
  for i in 1 2 3; do rmmod scsi_debug && break; sleep .2 || sleep 1; done
}

wait_for_dev_to_appear_()
{
  local file=$1
  local i=0
  local incr=1
  while :; do
    ls "$file" > /dev/null 2>&1 && return 0
    sleep .1 2>/dev/null || { sleep 1; incr=10; }
    i=$(expr $i + $incr); test $i = 20 && break
  done
  return 1
}

print_sd_names_() { (cd /sys/block && printf '%s\n' sd*); }

scsi_debug_setup_()
{
  local new_dev
  print_sd_names_ > before
  modprobe scsi_debug dev_size_mb=513 sector_size=4096
  local incr=1
  i=0
  while print_sd_names_ | cmp -s - before; do
    sleep .1 2>/dev/null || { sleep 1; incr=10; }
    i=$(expr $i + $incr); test $i = 20 && break
  done
  print_sd_names_ > after
  new_dev=$(comm -3 before after | tr -d '\011\012')
  rm -f before after
  test -z "$new_dev" && return 1
  local t=/dev/$new_dev
  wait_for_dev_to_appear_ $t
  echo $t
  return 0
}

# check for scsi_debug module
modprobe -n scsi_debug ||
  skip_test_ "you lack the scsi_debug kernel module"

grep '^#define USE_BLKID 1' "$CONFIG_HEADER" > /dev/null ||
  skip_test_ 'this system lacks a new-enough libblkid'

echo 'Sector size (logical/physical): 4096B/4096B' > exp || framework_failure

# create memory-backed device
dev=$(scsi_debug_setup_) ||
  skip_test_ 'failed to create scsi_debug device'

fail=0

# create partition table and print
parted -s $dev mklabel gpt print > out 2>&1 || fail=1
grep '^Sector' out > k 2>&1 || fail=1
mv k out || fail=1

compare out exp || fail=1

Exit $fail
