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

scsi_dev=
cleanup_() { scsi_debug_cleanup_; }

scsi_debug_cleanup_() {
  # Remove the module only if this script added it.
  test -z "$scsi_dev" && return

  # We have to insist.  Otherwise, a single rmmod usually fails to remove it,
  # due either to "Resource temporarily unavailable" or to
  # "Module scsi_debug is in use".
  for i in 1 2 3; do rmmod scsi_debug && break; sleep .2 || sleep 1; done
}

# Helper function: wait 2s (via .1s increments) for FILE to appear.
# Usage: wait_for_dev_to_appear_ /dev/sdg
# Return 0 upon success, 1 upon failure.
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

# Create a device using the scsi_debug module with the options passed to
# this function as arguments.  Upon success, print the name of the new device.
scsi_debug_setup_()
{
  # It is not trivial to determine the name of the device we're creating.
  # Record the names of all /sys/block/sd* devices *before* probing:
  print_sd_names_ > before
  modprobe scsi_debug "$@" || { rm -f before; return 1; }

  # Wait up to 2s (via .1s increments) for the list of devices to change.
  # Sleeping for a fraction of a second requires GNU sleep, so fall
  # back on sleeping 2x1s if that fails.
  # FIXME-portability: using "cmp - ..." probably requires GNU cmp.
  local incr=1
  local i=0
  while print_sd_names_ | cmp -s - before; do
    sleep .1 2>/dev/null || { sleep 1; incr=10; }
    i=$(expr $i + $incr); test $i = 20 && break
  done

  # Record the names of all /sys/block/sd* devices *after* probe+wait.
  print_sd_names_ > after

  # Determine which device names (if any) are new.
  # There could be more than one new device, and there have been a removal.
  local new_dev=$(comm -13 before after)
  rm -f before after
  case $new_dev in
    sd[a-z]) ;;
    sd[a-z][a-z]) ;;
    *) return 1 ;;
  esac
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
scsi_dev=$(scsi_debug_setup_ dev_size_mb=8 sector_size=4096) ||
  skip_test_ 'failed to create scsi_debug device'

fail=0

# create partition table and print
parted -s $scsi_dev mklabel gpt print > out 2>&1 || fail=1
grep '^Sector' out > k 2>&1 || fail=1
mv k out || fail=1

compare out exp || fail=1

Exit $fail
