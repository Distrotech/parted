/*
    partprobe - informs the OS kernel of partition layout
    Copyright (C) 2001, 2002 Free Software Foundation, Inc.

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

/* it's best to compile this with:
 *
 * 	 CFLAGS=-Os ./configure --disable-nls --disable-shared --disable-debug
 * 	 	    --enable-discover-only
 * 
 * And strip(1) afterwards!
 */

#include "config.h"

#include <parted/parted.h>

#include <stdio.h>
#include <string.h>

/* initialized to 0 according to the language lawyers */
static int	opt_no_probe;
static int	opt_summary;

static void
summary (PedDisk* disk)
{
	PedPartition*	walk;

	printf ("%s: %s partitions", disk->dev->path, disk->type->name);
	for (walk = disk->part_list; walk; walk = walk->next) {
		if (!ped_partition_is_active (walk))
			continue;

		printf (" %d", walk->num);
		if (walk->type & PED_PARTITION_EXTENDED) {
			PedPartition*	log_walk;
			int		is_first = 1;

			printf (" <");
			for (log_walk = walk->part_list; log_walk;
			     log_walk = log_walk->next) {
				if (!ped_partition_is_active (log_walk))
					continue;
				if (!is_first)
					printf (" ");
				printf ("%d", log_walk->num);
				is_first = 0;
			}
			printf (">");
		}
	}
	printf ("\n");
}

static int
process_dev (PedDevice* dev)
{
	PedDiskType*	disk_type;
	PedDisk*	disk;

	disk_type = ped_disk_probe (dev);
	if (!disk_type || !strcmp (disk_type->name, "loop"))
		return 1;

	disk = ped_disk_new (dev);
	if (!disk)
		goto error;
	if (!opt_no_probe) {
		if (!ped_disk_commit_to_os (disk))
			goto error_destroy_disk;
	}
	if (opt_summary)
		summary (disk);
	ped_disk_destroy (disk);
	return 1;

error_destroy_disk:
	ped_disk_destroy (disk);
error:
	return 0;
}

static void
help ()
{
	printf ("usage:  partprobe [-d] [-h] [-s] [-v] [DEVICES...]\n\n"
		"-d	don't update the kernel\n"
		"-s	print a summary of contents\n"
		"-v	version info\n");
}

static void
version ()
{
	printf ("partprobe (" PACKAGE VERSION ")\n");
}

int
main (int argc, char* argv[])
{
	int		dev_passed = 0;
	int		i;
	PedDevice*	dev;
	int		status = 1;

	for (i = 1; i < argc; i++) {
		if (argv[i][0] != '-') {
			dev_passed = 1;
			continue;
		}
		switch (argv[i][1]) {
			case '?':
			case 'h':
				help();
				return 0;

			case 'd': opt_no_probe = 1; break;
			case 's': opt_summary = 1; break;

			case 'v':
				version();
				return 0;
		}
	}

	if (dev_passed) {
		for (i = 1; i < argc; i++) {
			if (argv[i][0] == '-')
				continue;

			dev = ped_device_get (argv[i]);
			if (dev)
				status &= process_dev (dev);
			else
				status = 0;
		}
	} else {
		ped_device_probe_all ();
		for (dev = ped_device_get_next (NULL); dev;
		     dev = ped_device_get_next (dev))
			status &= process_dev (dev);
	}

	return !status;
}

