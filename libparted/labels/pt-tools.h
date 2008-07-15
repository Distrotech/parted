/* libparted - a library for manipulating disk partitions
   Copyright (C) 2008 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>. */

#include <stddef.h>
#include <parted/disk.h>

int ptt_write_sector (PedDisk const *disk, void const *buf, size_t buflen);
int ptt_read_sector (const PedDevice *dev, PedSector sector_num, void **buf);
