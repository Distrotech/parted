/*
    clear_fat - a tool to clear unused space (for testing purposes)
    Copyright (C) 2000 Free Software Foundation, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
*/

#include "config.h"

#include <string.h>
#include <stdio.h>

#ifndef DISCOVER_ONLY

#include "../../libparted/fs/fat/fat.h"

static char* help_msg =
"Usage:  clearfat DEVICE MINOR\n"
"\n"
"This program is used to enhance the automated testing.  It is not useful for\n"
"anything much else.\n";

#define CLEAR_BUFFER_SIZE		(1024 * 1024)
#define CLEAR_BUFFER_SECTORS		(CLEAR_BUFFER_SIZE/512)

static char buffer [CLEAR_BUFFER_SIZE];

static int
_do_help ()
{
	printf (help_msg);
	exit (1);
}

/* generic clearing code ***************************************************/

static int
_clear_sectors (PedGeometry* geom, PedSector start, PedSector count)
{
	PedSector		pos;
	PedSector		to_go = count;

	for (pos = start;
	     pos < start + count;
	     pos += CLEAR_BUFFER_SECTORS, to_go -= CLEAR_BUFFER_SECTORS) {
		if (!ped_geometry_write (geom, buffer, start,
					 PED_MIN (CLEAR_BUFFER_SECTORS, to_go)))
			return 0;
	}

	return 1;
}

static int
_clear_sector_range (PedGeometry* geom, PedSector start, PedSector end)
{
	return _clear_sectors (geom, start, end - start + 1);
}

static int
_clear_sector (PedGeometry* geom, PedSector sector)
{
	return _clear_sectors (geom, sector, 1);
}

static int
_clear_partial_sector (PedGeometry* geom, PedSector sector,
		       int offset, int count)
{
	if (!ped_geometry_read (geom, buffer, sector, 1))
		goto error;
	memset (buffer + offset, 0, count);
	if (!ped_geometry_write (geom, buffer, sector, 1))
		goto error;

	memset (buffer, 0, 512);
	return 1;

error:
	memset (buffer, 0, 512);
	return 0;
}

static int
_clear_partial_range (PedGeometry* geom, PedSector sector, int start, int end)
{
	return _clear_partial_sector (geom, sector, start, end - start + 1);
}

static int
_clear_clusters (PedFileSystem* fs, FatCluster start, FatCluster count)
{
	FatSpecific*	fs_info = FAT_SPECIFIC (fs);
	return _clear_sectors (fs->geom, fat_cluster_to_sector(fs, start),
			       count * fs_info->cluster_sectors);
}

/* FAT code ******************************************************************/

static void
_clear_before_fat (PedFileSystem* fs)
{
	FatSpecific*	fs_info = FAT_SPECIFIC (fs);
	PedSector	sector;

	for (sector = 1; sector < fs_info->fat_offset; sector++) {
		if (sector == fs_info->info_sector_offset)
			continue;
		if (sector == fs_info->boot_sector_backup_offset)
			continue;
		_clear_sector (fs->geom, sector);
	}
}

static int
_calc_fat_entry_offset (PedFileSystem* fs, FatCluster cluster)
{
	FatSpecific*	fs_info = FAT_SPECIFIC (fs);

	switch (fs_info->fat_type) {
		case FAT_TYPE_FAT16:
			return cluster * 2;

		case FAT_TYPE_FAT32:
			return cluster * 4;
	}
	return 0;
}

static void
_clear_unused_fats (PedFileSystem* fs)
{
	FatSpecific*	fs_info = FAT_SPECIFIC (fs);
	PedSector	table_start;
	int		table_num;
	int		last_active_offset;
	PedSector	last_active_sector;
	int		last_active_sector_offset;

	last_active_offset
		= _calc_fat_entry_offset (fs, fs_info->fat->cluster_count);
	last_active_sector = last_active_offset / 512;
	last_active_sector_offset = last_active_offset % 512 + 4;

	for (table_num = 0; table_num < fs_info->fat_table_count; table_num++) {
		table_start = fs_info->fat_offset
			      + table_num * fs_info->fat_sectors;

		if (last_active_sector_offset < 512) {
			_clear_partial_range (
				fs->geom,
				table_start + last_active_sector,
				last_active_sector_offset,
				512);
		}

		if (last_active_sector < fs_info->fat_sectors - 2) {
			_clear_sector_range (
				fs->geom,
				table_start + last_active_sector + 1,
				table_start + fs_info->fat_sectors - 1);
		}
	}
}

static int
_clear_unused_clusters (PedFileSystem* fs)
{
	FatSpecific*	fs_info = FAT_SPECIFIC (fs);
	FatCluster	cluster;
	FatCluster	run_start = 0; /* shut gcc up! */
	FatCluster	run_length = 0;

	for (cluster = 2; cluster < fs_info->cluster_count + 2; cluster++) {
		if (fat_table_is_available (fs_info->fat, cluster)) {
			if (!run_length) {
				run_start = cluster;
				run_length = 1;
			} else {
				run_length++;
			}
		} else {
			if (run_length)
				_clear_clusters (fs, run_start, run_length);
			run_length = 0;
		}
	}

	if (run_length)
		_clear_clusters (fs, run_start, run_length);

	return 1;
}

static void
_clear_unused_fat (PedFileSystem* fs)
{
	memset (buffer, 0, CLEAR_BUFFER_SIZE);

	_clear_before_fat (fs);
	_clear_unused_fats (fs);
	_clear_unused_clusters (fs);
}

/* bureaucracy ***************************************************************/

int
main (int argc, char* argv[])
{
	PedDevice*		dev;
	PedDisk*		disk;
	PedPartition*		part;
	PedFileSystem*		fs;

	if (argc < 3)
		_do_help ();

	dev = ped_device_get (argv [1]);
	if (!dev)
		goto error;
	if (!ped_device_open (dev))
		goto error;

	disk = ped_disk_new (dev);
	if (!disk)
		goto error_close_dev;
 
	part = ped_disk_get_partition (disk, atoi (argv[2]));
	if (!part) {
		printf ("Couldn't find partition `%s'\n", argv[2]);
		goto error_destroy_disk;
	}

	fs = ped_file_system_open (&part->geom);
	if (!fs)
		goto error_destroy_disk;

	if (strncmp (fs->type->name, "fat", 3)) {
		printf ("Not a FAT file system!\n");
		goto error_close_fs;
	}

	_clear_unused_fat (fs);

	ped_file_system_close (fs);
	ped_disk_destroy (disk);
	ped_device_close (dev);
	return 0;

error_close_fs:
	ped_file_system_close (fs);
error_destroy_disk:
	ped_disk_destroy (disk);
error_close_dev:
	ped_device_close (dev);
error:
	return 1;
}

#else /* DISCOVER_ONLY */

/* hack! */
int
main()
{
	printf ("You must compile libparted with full read/write support\n");
	return 1;
}

#endif /* DISCOVER_ONLY */

