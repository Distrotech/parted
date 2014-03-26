#!/bin/sh
# ensure parted can ignore partitions that overlap or are
# longer than the disk and remove them

# Copyright (C) 2009-2012 Free Software Foundation, Inc.

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
require_512_byte_sector_size_
dev=loop-file

truncate -s 10m $dev || fail=1

# write damaged label
xxd -r - $dev <<EOF
0000000: fab8 0010 8ed0 bc00 b0b8 0000 8ed8 8ec0  ................
0000010: fbbe 007c bf00 06b9 0002 f3a4 ea21 0600  ...|.........!..
0000020: 00be be07 3804 750b 83c6 1081 fefe 0775  ....8.u........u
0000030: f3eb 16b4 02b0 01bb 007c b280 8a74 018b  .........|...t..
0000040: 4c02 cd13 ea00 7c00 00eb fe00 0000 0000  L.....|.........
0000050: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000060: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000070: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000080: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000090: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000a0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000b0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000c0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000d0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000e0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000f0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000100: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000110: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000120: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000130: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000140: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000150: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000160: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000170: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000180: 0000 0000 0000 0000 0000 0000 0000 0000  ................
0000190: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00001a0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00001b0: 0000 0000 0000 0000 72f5 0000 0000 0000  ........r.......
00001c0: 0110 8303 204f 0008 0000 0020 0000 0000  .... O..... ....
00001d0: 0050 8300 0a7a ff27 0000 0a15 0000 0000  .P...z.'........
00001e0: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00001f0: 0000 0000 0000 0000 0000 0000 0000 55aa  ..............U.
EOF

# print the empty table
parted ---pretend-input-tty $dev <<EOF > out 2>&1 || fail=1
print
ignore
rm
ignore
2
EOF

# $PWD contains a symlink-to-dir.  Also, remove the ^M      ...^M bogosity.
# normalize the actual output
mv out o2 && sed -e "s,/.*/$dev,DEVICE,;s,   *,,g;s, $,," \
                      -e "s,^.*/lt-parted: ,parted: ," -e "s/^GNU Parted .*$/GNU Parted VERSION/" o2 > out

# check for expected output
emit_superuser_warning > exp || fail=1
cat <<EOF >> exp || fail=1
GNU Parted VERSION
Using DEVICE
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) print
Error: Can't have overlapping partitions.
Ignore/Cancel? ignore
Model:  (file)
Disk DEVICE: 10.5MB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags:

Number  Start   End     Size    Type     File system  Flags
 1      1049kB  5243kB  4194kB  primary
 2      5242kB  8000kB  2758kB  primary

(parted) rm
Error: Can't have overlapping partitions.
Ignore/Cancel? ignore
Partition number? 2
(parted)
EOF
compare exp out || fail=1

truncate -s 3m $dev || fail=1

# print the table, verify error, ignore it, and remove the partition
parted ---pretend-input-tty $dev <<EOF > out 2>&1 || fail=1
print
ignore
rm
ignore
1
EOF

# $PWD contains a symlink-to-dir.  Also, remove the ^M      ...^M bogosity.
# normalize the actual output
mv out o2 && sed -e "s,/.*/$dev,DEVICE,;s,   *,,g;s, $,," \
                      -e "s,^.*/lt-parted: ,parted: ," -e "s/^GNU Parted .*$/GNU Parted VERSION/" o2 > out

# check for expected output
emit_superuser_warning > exp || fail=1
cat <<EOF >> exp || fail=1
GNU Parted VERSION
Using DEVICE
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) print
Error: Can't have a partition outside the disk!
Ignore/Cancel? ignore
Model:  (file)
Disk DEVICE: 3146kB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags:

Number  Start   End     Size    Type     File system  Flags
 1      1049kB  5243kB  4194kB  primary

(parted) rm
Error: Can't have a partition outside the disk!
Ignore/Cancel? ignore
Partition number? 1
(parted)
EOF
compare exp out || fail=1

Exit $fail
