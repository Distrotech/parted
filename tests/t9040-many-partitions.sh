#!/bin/sh
# Ensure that creating many partitions works.

# Copyright (C) 2010-2011 Free Software Foundation, Inc.

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

. "${srcdir=.}/init.sh"; path_prepend_ ../parted

require_root_
require_scsi_debug_module_

grep '^#define USE_BLKID 1' "$CONFIG_HEADER" > /dev/null ||
  skip_ 'this system lacks a new-enough libblkid'

ss=$sector_size_
partition_sectors=256  # sectors per partition
n_partitions=60        # how many partitions to create
start=2048             # start sector for the first partition
gpt_slop=34            # sectors at end of disk reserved for GPT

n_sectors=$(($start + n_partitions * partition_sectors + gpt_slop))

sectors_per_MiB=$((1024 * 1024 / ss))
n_MiB=$(((n_sectors + sectors_per_MiB - 1) / sectors_per_MiB))
# create memory-backed device
scsi_debug_setup_ sector_size=$ss dev_size_mb=$n_MiB > dev-name ||
  skip_ 'failed to create scsi_debug device'
scsi_dev=$(cat dev-name)

n=$((n_MiB * sectors_per_MiB))
printf "BYT;\n$scsi_dev:${n}s:scsi:$ss:$ss:gpt:Linux scsi_debug;\n" \
  > exp || fail=1

parted -s $scsi_dev mklabel gpt || fail=1
parted -s $scsi_dev u s p || fail=1

i=1
t0=$(date +%s.%N)
while :; do
    end=$((start + partition_sectors - 1))
    parted -s $scsi_dev mkpart p$i ${start}s ${end}s || fail=1
    printf "$i:${start}s:${end}s:${partition_sectors}s::p$i:;\n" >> exp
    test $i = $n_partitions && break
    start=$((start + partition_sectors))
    i=$((i+1))
done
t_final=$(date +%s.%N)

# Fail the test if it takes too long.
# On Fedora 13, it takes about 15 seconds.
# With older kernels, it typically takes more than 150 seconds.
$AWK "BEGIN {d = $t_final - $t0; n = $n_partitions; st = 60 < d;"\
' printf "created %d partitions in %.2f seconds\n", n, d; exit st }' /dev/null \
    || fail=1

parted -m -s $scsi_dev u s p > out || fail=1
compare out exp || fail=1

# We must remove these partitions before terminating.
# Otherwise, even though cleanup-driven rmmod will eventually cause
# them to be removed, they may continue to be removed long after
# the rmmod cleanup lock has been released, and such removals
# can (and regularly did) interfere with the following test.
i=1
while :; do
    parted -s $scsi_dev rm $i || fail=1
    test $i = $n_partitions && break
    i=$((i+1))
done

Exit $fail
