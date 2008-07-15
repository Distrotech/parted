/* partition table tools
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

#include <config.h>

#include <string.h>
#include <stdlib.h>

#include <parted/parted.h>
#include <parted/debug.h>

#include "pt-tools.h"

/* Write a single sector to DISK, filling the first BUFLEN
   bytes of that sector with data from BUF, and NUL-filling
   any remaining bytes.  Return nonzero to indicate success,
   zero otherwise.  */
int
ptt_write_sector (PedDisk const *disk, void const *buf, size_t buflen)
{
  PED_ASSERT (buflen <= disk->dev->sector_size, return 0);
  /* Allocate a big enough buffer for ped_device_write.  */
  char *s0 = ped_malloc (disk->dev->sector_size);
  if (s0 == NULL)
    return 0;
  /* Copy boot_code into the first part.  */
  memcpy (s0, buf, buflen);
  char *p = s0 + buflen;
  /* Fill the rest with zeros.  */
  memset (p, 0, disk->dev->sector_size - buflen);
  int write_ok = ped_device_write (disk->dev, s0, 0, 1);
  free (s0);

  return write_ok;
}

/* Read sector, SECTOR_NUM (which has length DEV->sector_size) into malloc'd
   storage.  If the read fails, free the memory and return zero without
   modifying *BUF.  Otherwise, set *BUF to the new buffer and return 1.  */
int
ptt_read_sector (PedDevice const *dev, PedSector sector_num, void **buf)
{
  char *b = ped_malloc (dev->sector_size);
  PED_ASSERT (b != NULL, return 0);
  if (!ped_device_read (dev, b, sector_num, 1)) {
    free (b);
    return 0;
  }
  *buf = b;
  return 1;
}
