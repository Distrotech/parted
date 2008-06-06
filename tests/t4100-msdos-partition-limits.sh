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

test_description='enforce limits on partition start sector and length'

# Need root privileges to use mount.
privileges_required_=1

: ${srcdir=.}
. $srcdir/test-lib.sh

####################################################
# Create and mount a file system capable of dealing with >=2TB files.
# We must be able to create a file with an apparent length of 2TB or larger.
# It needn't be a large file system.
fs=fs_file
mp=`pwd`/mount-point
n=4096

test_expect_success \
    'create an XFS file system' \
    '
    dd if=/dev/zero of=$fs bs=1MB count=2 seek=20 &&
    mkfs.xfs -q $fs &&
    mkdir "$mp"

    '

# Unmount upon interrupt, failure, etc., as well as upon normal completion.
cleanup_() { cd "$test_dir_" && umount "$mp" > /dev/null 2>&1; }

test_expect_success \
    'mount it' \
    '
    mount -o loop $fs "$mp" &&
    cd "$mp"

    '
dev=loop-file

do_mkpart()
{
  start_sector=$1
  end_sector=$2
  # echo '********' $(echo $end_sector - $start_sector + 1 |bc)
  dd if=/dev/zero of=$dev bs=1b count=2k seek=$end_sector 2> /dev/null &&
  parted -s $dev mklabel $table_type &&
  parted -s $dev mkpart p xfs ${start_sector}s ${end_sector}s
}

# Specify the starting sector number and length in sectors,
# rather than start and end.
do_mkpart_start_and_len()
{
  start_sector=$1
  len=$2
  end_sector=$(echo $start_sector + $len - 1|bc)
  do_mkpart $start_sector $end_sector
}

for table_type in msdos; do

test_expect_success \
    "$table_type: a partition length of 2^32-1 works." \
    '
    end=$(echo $n+2^32-2|bc) &&
    do_mkpart $n $end
    '

test_expect_success \
    'print the result' \
    'parted -s $dev unit s p > out 2>&1 &&
     sed -n "/^  *1  *$n/s/  */ /gp" out|sed "s/  *\$//" > k && mv k out &&
     echo " 1 ${n}s ${end}s 4294967295s primary" > exp &&
     diff -u out exp
    '

test_expect_failure \
    "$table_type: a partition length of exactly 2^32 sectors provokes failure." \
    'do_mkpart $n $(echo $n+2^32-1|bc) > err 2>&1'

bad_part_length()
{ echo "Error: partition length of $1 sectors exceeds the"\
  "$table_type-partition-table-imposed maximum of 4294967295"; }
test_expect_success \
    'check for new diagnostic' \
    'bad_part_length 4294967296 > exp && diff -u err exp'

# FIXME: investigate this.
# Unexpectedly to me, both of these failed with this same diagnostic:
#
#   Error: partition length of 4294967296 sectors exceeds the \
#   DOS-partition-table-imposed maximum of 2^32-1" > exp &&
#
# I expected the one below to fail with a length of _4294967297_.
# Debugging, I see that _check_partition *does* detect this,
# but the diagnostic doesn't get displayed because of the wonders
# of parted's exception mechanism.

test_expect_failure \
    "$table_type: a partition length of 2^32+1 sectors provokes failure." \
    'do_mkpart $n $(echo $n+2^32|bc) > err 2>&1'

# FIXME: odd that we asked for 2^32+1, yet the diagnostic says 2^32
# FIXME: Probably due to constraints.
# FIXME: For now, just accept the current output.
test_expect_success \
    'check for new diagnostic' \
    'bad_part_length 4294967296 > exp && diff -u err exp'

# =========================================================
# Now consider partition starting sector numbers.
bad_start_sector()
{ echo "Error: starting sector number, $1 exceeds the"\
  "$table_type-partition-table-imposed maximum of 4294967295"; }

test_expect_success \
    "$table_type: a partition start sector number of 2^32-1 works." \
    'do_mkpart_start_and_len $(echo 2^32-1|bc) 1000'

cat > exp <<EOF
Model:  (file)
Disk: 4294970342s
Sector size (logical/physical): 512B/512B
Partition Table: $table_type

Number  Start        End          Size   Type     File system  Flags
 1      4294967295s  4294968294s  1000s  primary

EOF

test_expect_success \
    'print the result' \
    'parted -s $dev unit s p > out 2>&1 &&
     sed "s/Disk .*:/Disk:/;s/ *$//" out > k && mv k out &&
     diff -u out exp
    '

test_expect_failure \
    "$table_type: a partition start sector number of 2^32 must fail." \
    'do_mkpart_start_and_len $(echo 2^32|bc) 1000 > err 2>&1'
test_expect_success \
    'check for new diagnostic' \
    'bad_start_sector 4294967296 > exp && diff -u err exp'

test_expect_failure \
    "$table_type: a partition start sector number of 2^32+1 must fail, too." \
    'do_mkpart_start_and_len $(echo 2^32+1|bc) 1000 > err 2>&1'
test_expect_success \
    'check for new diagnostic' \
    'bad_start_sector 4294967296 > exp && diff -u err exp'

done

test_done
