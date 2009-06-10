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

test_description='Ignore devices that start with md from /sys/block.'

privileges_required_=1
# This will setup private /dev and /etc
device_mapper_required_=1

: ${srcdir=.}
. $srcdir/test-lib.sh

test "x$ENABLE_DEVICE_MAPPER" = xyes ||
  {
    say "skipping $0: no device-mapper support"
    test_done
    exit
  }

test -d /sys/block ||
  {
    say "skipping $0: system does not have /sys/block"
    test_done
    exit
  }

which mdadm > /dev/null 2>&1 ||
  {
    say "skipping $0: could not find mdadm executable"
    test_done
    exit
  }

# The md device.
mddev_=

cleanup_() {
    mdadm --stop $mddev_ > /dev/null 2>&1
    test -n "$d1" && losetup -d "$d1"
    rm -f "$f1";
}

md_dev_create_()
{
  lo_dev=$1
  mdd=$G_dev_/md0
  for i in 0 1 2 3 4 5 6 7 8 9 ; do
      mdd=$G_dev_/md$i
      mdadm  --create --force $mdd --level=linear --raid-devices=1 $lo_dev > /dev/null 2>&1 \
      && break

      if [ $i -eq 9 ]; then echo $mdd ; return 1 ; fi
  done

  echo $mdd
  return 0
}

test_expect_success \
    'setup: create loop devices' \
    'f1=$(pwd)/1 && d1=$(loop_setup_ "$f1")'

test_expect_success \
    'setup: create md# device' \
    'mddev_=$(md_dev_create_ "$d1")'

test_expect_failure \
    'grep for the created md device' \
    'parted -s -m -l | grep "Error:.*: unrecognised disk label"'

test_done
