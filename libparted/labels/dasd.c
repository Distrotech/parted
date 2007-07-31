/* -*- Mode: c; tab-width: 8; indent-tabs-mode: nil; c-basic-offset: 8 -*-

    libparted - a library for manipulating disk partitions
    Copyright (C) 2000, 2001, 2007 Free Software Foundation, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Contributor:  Phil Knirsch <phil@redhat.de>
                  Harald Hoyer <harald@redhat.de>
*/

#include <config.h>

#include <stdio.h>
#include <errno.h>
#include <ctype.h>
#include <time.h>
#include <fcntl.h>
#include <unistd.h>

#include <sys/stat.h>
#include <sys/ioctl.h>
#include <parted/parted.h>
#include <parted/endian.h>
#include <parted/debug.h>

#include <parted/vtoc.h>
#include <parted/fdasd.h>
#include <parted/linux.h>

#include <libintl.h>
#if ENABLE_NLS
#  define _(String) dgettext (PACKAGE, String)
#else
#  define _(String) (String)
#endif /* ENABLE_NLS */

#define PARTITION_LINUX_SWAP 0x82
#define PARTITION_LINUX 0x83
#define PARTITION_LINUX_EXT 0x85
#define PARTITION_LINUX_LVM 0x8e
#define PARTITION_LINUX_RAID 0xfd
#define PARTITION_LINUX_LVM_OLD 0xfe

extern void ped_disk_dasd_init ();
extern void ped_disk_dasd_done ();

#define DASD_NAME "dasd"

typedef struct {
	int type;
	int system;
	int	raid;
	int	lvm;
	void *part_info;
} DasdPartitionData;

typedef struct {
	unsigned int real_sector_size;
	unsigned int format_type;
	/* IBM internal dasd structure (i guess ;), required. */
	struct fdasd_anchor *anchor;
} DasdDiskSpecific;

static int dasd_probe (const PedDevice *dev);
static int dasd_clobber (PedDevice* dev);
static int dasd_read (PedDisk* disk);
static int dasd_write (const PedDisk* disk);

static PedPartition* dasd_partition_new (const PedDisk* disk,
										 PedPartitionType part_type,
										 const PedFileSystemType* fs_type,
										 PedSector start,
										 PedSector end);
static void dasd_partition_destroy (PedPartition* part);
static int dasd_partition_set_flag (PedPartition* part,
									PedPartitionFlag flag,
									int state);
static int dasd_partition_get_flag (const PedPartition* part,
									PedPartitionFlag flag);
static int dasd_partition_is_flag_available (const PedPartition* part,
											 PedPartitionFlag flag);
static int dasd_partition_align (PedPartition* part,
								 const PedConstraint* constraint);
static int dasd_partition_enumerate (PedPartition* part);
static int dasd_get_max_primary_partition_count (const PedDisk* disk);

static PedDisk* dasd_alloc (const PedDevice* dev);
static PedDisk* dasd_duplicate (const PedDisk* disk);
static void dasd_free (PedDisk* disk);
static int dasd_partition_set_system (PedPartition* part,
									  const PedFileSystemType* fs_type);
static int dasd_alloc_metadata (PedDisk* disk);

static PedDiskOps dasd_disk_ops = {
	probe: dasd_probe,
	clobber: dasd_clobber,
	read: dasd_read,
	write: dasd_write,

	alloc: dasd_alloc,
	duplicate: dasd_duplicate,
	free: dasd_free,
	partition_set_system: dasd_partition_set_system,

	partition_new: dasd_partition_new,
	partition_destroy: dasd_partition_destroy,
	partition_set_flag:	dasd_partition_set_flag,
	partition_get_flag:	dasd_partition_get_flag,
	partition_is_flag_available: dasd_partition_is_flag_available,
	partition_set_name:	NULL,
	partition_get_name:	NULL,
	partition_align: dasd_partition_align,
	partition_enumerate: dasd_partition_enumerate,

	alloc_metadata: dasd_alloc_metadata,
	get_max_primary_partition_count: dasd_get_max_primary_partition_count,

	partition_duplicate: NULL
};

static PedDiskType dasd_disk_type = {
	next: NULL,
	name: "dasd",
	ops: &dasd_disk_ops,
	features: 0
};

static PedDisk*
dasd_alloc (const PedDevice* dev)
{
	PedDisk* disk;
	LinuxSpecific* arch_specific;
	DasdDiskSpecific *disk_specific;

	PED_ASSERT (dev != NULL, return NULL);

	arch_specific = LINUX_SPECIFIC (dev);
	disk = _ped_disk_alloc (dev, &dasd_disk_type);
	if (!disk)
		return NULL;

	disk->disk_specific = disk_specific = ped_malloc(sizeof(DasdDiskSpecific));
	if (!disk->disk_specific) {
		ped_free (disk);
		return NULL;
	}

	/* because we lie to parted we have to compensate with the
	   real sector size.  Record that now. */
	if (ioctl(arch_specific->fd, BLKSSZGET,
			  &disk_specific->real_sector_size) == -1) {
		ped_exception_throw(PED_EXCEPTION_ERROR, PED_EXCEPTION_CANCEL,
							_("Unable to determine the block "
							  "size of this dasd"));
		ped_free(disk_specific);
		ped_free(disk);
		return NULL;
	}

	return disk;
}

static PedDisk*
dasd_duplicate (const PedDisk* disk)
{
	PedDisk* new_disk;

	new_disk = ped_disk_new_fresh(disk->dev, &dasd_disk_type);

	if (!new_disk)
		return NULL;

	new_disk->disk_specific = NULL;

	return new_disk;
}

static void
dasd_free (PedDisk* disk)
{
	PED_ASSERT(disk != NULL, return);

	_ped_disk_free(disk);
}


void
ped_disk_dasd_init ()
{
	ped_disk_type_register(&dasd_disk_type);
}

void
ped_disk_dasd_done ()
{
	ped_disk_type_unregister(&dasd_disk_type);
}

static int
dasd_probe (const PedDevice *dev)
{
	char *errstr = 0;
	LinuxSpecific* arch_specific;
	struct fdasd_anchor anchor;

	PED_ASSERT(dev != NULL, return 0);

	if (!(dev->type == PED_DEVICE_DASD || dev->type == PED_DEVICE_VIODASD))
		return 0;

	arch_specific = LINUX_SPECIFIC(dev);

	/* add partition test here */
	fdasd_initialize_anchor(&anchor);

	fdasd_get_geometry(&anchor, arch_specific->fd);

	fdasd_check_api_version(&anchor, arch_specific->fd);

	if (fdasd_check_volume(&anchor, arch_specific->fd))
		goto error_cleanup;

	fdasd_cleanup(&anchor);

	return 1;

error_cleanup:
	fdasd_cleanup(&anchor);
	ped_exception_throw(PED_EXCEPTION_ERROR,PED_EXCEPTION_IGNORE_CANCEL,errstr);

	return 0;
}

static int
dasd_clobber (PedDevice* dev)
{
	LinuxSpecific* arch_specific;
	struct fdasd_anchor anchor;

	PED_ASSERT(dev != NULL, return 0);

	arch_specific = LINUX_SPECIFIC(dev);

	fdasd_initialize_anchor(&anchor);
	fdasd_get_geometry(&anchor, arch_specific->fd);

	fdasd_recreate_vtoc(&anchor);
	fdasd_write_labels(&anchor, arch_specific->fd);

	return 1;
}

static int
dasd_read (PedDisk* disk)
{
	int i;
	char str[20];
	PedDevice* dev;
	PedPartition* part;
	PedFileSystemType *fs;
	PedSector start, end;
	PedConstraint* constraint_exact;
	partition_info_t *p;
	LinuxSpecific* arch_specific;
	DasdDiskSpecific* disk_specific;

	PDEBUG;

	PED_ASSERT (disk != NULL, return 0);
	PDEBUG;
	PED_ASSERT (disk->dev != NULL, return 0);
	PDEBUG;

	dev = disk->dev;

	arch_specific = LINUX_SPECIFIC(dev);
	disk_specific = disk->disk_specific;

	disk_specific->anchor = ped_malloc(sizeof(fdasd_anchor_t));

	PDEBUG;

	fdasd_initialize_anchor(disk_specific->anchor);

	fdasd_get_geometry(disk_specific->anchor, arch_specific->fd);

	/* check dasd for labels and vtoc */
	if (fdasd_check_volume(disk_specific->anchor, arch_specific->fd))
		goto error_close_dev;

	if ((disk_specific->anchor->geo.cylinders
		* disk_specific->anchor->geo.heads) > BIG_DISK_SIZE)
		disk_specific->anchor->big_disk++;

	ped_disk_delete_all (disk);

	if (strncmp(disk_specific->anchor->vlabel->volkey,
				vtoc_ebcdic_enc ("LNX1", str, 4), 4) == 0) {
		DasdPartitionData* dasd_data;

		/* LDL format, old one */
		disk_specific->format_type = 1;
		start = 24;
		end = (long long)(long long) disk_specific->anchor->geo.cylinders
		      * (long long)disk_specific->anchor->geo.heads
		      * (long long)disk->dev->hw_geom.sectors
		      * (long long)disk_specific->real_sector_size
		      / (long long)disk->dev->sector_size - 1;
		part = ped_partition_new (disk, PED_PARTITION_PROTECTED, NULL, start, end);
		if (!part)
			goto error_close_dev;

		part->num = 1;
		part->fs_type = ped_file_system_probe (&part->geom);
		dasd_data = part->disk_specific;
		dasd_data->raid = 0;
		dasd_data->lvm = 0;
		dasd_data->type = 0;

		if (!ped_disk_add_partition (disk, part, NULL))
			goto error_close_dev;

		return 1;
	}

	/* CDL format, newer */
	disk_specific->format_type = 2;

	p = disk_specific->anchor->first;
	PDEBUG;

	for (i = 1 ; i <= USABLE_PARTITIONS; i++) {
		char *ch = p->f1->DS1DSNAM;
		DasdPartitionData* dasd_data;


		if (p->used != 0x01)
			continue;

        PDEBUG;

		start = (long long)(long long) p->start_trk
				* (long long) disk->dev->hw_geom.sectors
				* (long long) disk_specific->real_sector_size
				/ (long long) disk->dev->sector_size;
		end   = (long long)((long long) p->end_trk + 1)
				* (long long) disk->dev->hw_geom.sectors
				* (long long) disk_specific->real_sector_size
				/ (long long) disk->dev->sector_size - 1;
		part = ped_partition_new(disk, 0, NULL, start, end);
        PDEBUG;

		if (!part)
			goto error_close_dev;

        PDEBUG;

		part->num = i;
		part->fs_type = ped_file_system_probe(&part->geom);

		vtoc_ebcdic_dec(p->f1->DS1DSNAM, p->f1->DS1DSNAM, 44);
		ch = strstr(p->f1->DS1DSNAM, "PART");

		if (ch != NULL) {
			strncpy(str, ch+9, 6);
			str[6] = '\0';
		}

		dasd_data = part->disk_specific;

		if ((strncmp(PART_TYPE_RAID, str, 6) == 0) &&
		    (ped_file_system_probe(&part->geom) == NULL))
			ped_partition_set_flag(part, PED_PARTITION_RAID, 1);
		else
			ped_partition_set_flag(part, PED_PARTITION_RAID, 0);

		if ((strncmp(PART_TYPE_LVM, str, 6) == 0) &&
		    (ped_file_system_probe(&part->geom) == NULL))
			ped_partition_set_flag(part, PED_PARTITION_LVM, 1);
		else
			ped_partition_set_flag(part, PED_PARTITION_LVM, 0);

		if (strncmp(PART_TYPE_SWAP, str, 6) == 0) {
			fs = ped_file_system_probe(&part->geom);
			if (strncmp(fs->name, "linux-swap", 10) == 0) {
				dasd_data->system = PARTITION_LINUX_SWAP;
				PDEBUG;
			}
		}

		vtoc_ebcdic_enc(p->f1->DS1DSNAM, p->f1->DS1DSNAM, 44);

		dasd_data->part_info = (void *) p;
		dasd_data->type = 0;

		constraint_exact = ped_constraint_exact (&part->geom);
		if (!constraint_exact)
			goto error_close_dev;
		if (!ped_disk_add_partition(disk, part, constraint_exact))
			goto error_close_dev;
		ped_constraint_destroy(constraint_exact);

		if (p->fspace_trk > 0) {
			start = (long long)((long long) p->end_trk + 1)
					* (long long) disk->dev->hw_geom.sectors
					* (long long) disk_specific->real_sector_size
					/ (long long) disk->dev->sector_size;
			end   = (long long)((long long) p->end_trk + 1 + p->fspace_trk)
					* (long long) disk->dev->hw_geom.sectors
					* (long long) disk_specific->real_sector_size
					/ (long long) disk->dev->sector_size - 1;
			part = ped_partition_new (disk, 0, NULL, start, end);

			if (!part)
				goto error_close_dev;

			part->type = PED_PARTITION_FREESPACE;
			constraint_exact = ped_constraint_exact(&part->geom);

			if (!constraint_exact)
				goto error_close_dev;
			if (!ped_disk_add_partition(disk, part, constraint_exact))
				goto error_close_dev;

			ped_constraint_destroy (constraint_exact);
		}

		p = p->next;
	}

	PDEBUG;
	return 1;

error_close_dev:
	PDEBUG;
	return 0;
}

static int
dasd_update_type (const PedDisk* disk)
{
	PedPartition* part;
	LinuxSpecific* arch_specific;
	DasdDiskSpecific* disk_specific;

	arch_specific = LINUX_SPECIFIC(disk->dev);
	disk_specific = disk->disk_specific;

	PDEBUG;

	for (part = ped_disk_next_partition(disk, NULL); part;
	     part = ped_disk_next_partition(disk, part)) {
		partition_info_t *p;
		char *ch = NULL;
		DasdPartitionData* dasd_data;

		PDEBUG;

		if (part->type & PED_PARTITION_FREESPACE
			|| part->type & PED_PARTITION_METADATA)
			continue;

		PDEBUG;

		dasd_data = part->disk_specific;
		p = dasd_data->part_info;

		if (!p ) {
			PDEBUG;
			continue;
		}

		vtoc_ebcdic_dec(p->f1->DS1DSNAM, p->f1->DS1DSNAM, 44);
		ch = strstr(p->f1->DS1DSNAM, "PART");

		PDEBUG;
		if (ch == NULL) {
			vtoc_ebcdic_enc(p->f1->DS1DSNAM, p->f1->DS1DSNAM, 44);
			PDEBUG;
			continue;
		}

		ch += 9;

		switch (dasd_data->system) {
			case PARTITION_LINUX_LVM:
				PDEBUG;
				strncpy(ch, PART_TYPE_LVM, 6);
				break;
			case PARTITION_LINUX_RAID:
				PDEBUG;
				strncpy(ch, PART_TYPE_RAID, 6);
				break;
			case PARTITION_LINUX:
				PDEBUG;
				strncpy(ch, PART_TYPE_NATIVE, 6);
				break;
			case PARTITION_LINUX_SWAP:
				PDEBUG;
				strncpy(ch, PART_TYPE_SWAP, 6);
				break;
			default:
				PDEBUG;
				strncpy(ch, PART_TYPE_NATIVE, 6);
				break;
		}

		disk_specific->anchor->vtoc_changed++;
		vtoc_ebcdic_enc(p->f1->DS1DSNAM, p->f1->DS1DSNAM, 44);
	}

	return 1;
}

static int
dasd_write (const PedDisk* disk)
{
	DasdPartitionData* dasd_data;
	PedPartition* part;
	int i;
	partition_info_t *p;
	LinuxSpecific* arch_specific;
	DasdDiskSpecific* disk_specific;
	PED_ASSERT(disk != NULL, return 0);
	PED_ASSERT(disk->dev != NULL, return 0);

	arch_specific = LINUX_SPECIFIC (disk->dev);
	disk_specific = disk->disk_specific;

	PDEBUG;

	/* If formated in LDL, don't write anything. */
	if (disk_specific->format_type == 1)
		return 1;

	/* XXX re-initialize anchor? */
	fdasd_initialize_anchor(disk_specific->anchor);
	fdasd_get_geometry(disk_specific->anchor, arch_specific->fd);

	/* check dasd for labels and vtoc */
	if (fdasd_check_volume(disk_specific->anchor, arch_specific->fd))
		goto error;

	if ((disk_specific->anchor->geo.cylinders
		* disk_specific->anchor->geo.heads) > BIG_DISK_SIZE)
		disk_specific->anchor->big_disk++;

	fdasd_recreate_vtoc(disk_specific->anchor);

	for (i = 1; i <= USABLE_PARTITIONS; i++) {
		unsigned int start, stop;
		int type;

		PDEBUG;
		part = ped_disk_get_partition(disk, i);
		if (!part)
			continue;

		PDEBUG;

		start = part->geom.start * disk->dev->sector_size
				/ disk_specific->real_sector_size / disk->dev->hw_geom.sectors;
		stop = (part->geom.end + 1)
			   * disk->dev->sector_size / disk_specific->real_sector_size
			   / disk->dev->hw_geom.sectors - 1;

		PDEBUG;
		dasd_data = part->disk_specific;

		type = dasd_data->type;
		PDEBUG;

		p = fdasd_add_partition(disk_specific->anchor, start, stop);
		if (!p) {
			PDEBUG;
			return 0;
		}
		dasd_data->part_info = (void *) p;
		p->type = dasd_data->system;
	}

	PDEBUG;

	if (!fdasd_prepare_labels(disk_specific->anchor, arch_specific->fd))
		return 0;

	dasd_update_type(disk);
	PDEBUG;

	if (!fdasd_write_labels(disk_specific->anchor, arch_specific->fd))
		return 0;

	return 1;

error:
	PDEBUG;
	return 0;
}

static PedPartition*
dasd_partition_new (const PedDisk* disk, PedPartitionType part_type,
                    const PedFileSystemType* fs_type,
                    PedSector start, PedSector end)
{
	PedPartition* part;

	part = _ped_partition_alloc(disk, part_type, fs_type, start, end);
	if (!part)
		goto error;

	part->disk_specific = ped_malloc (sizeof (DasdPartitionData));
	return part;

error:
	return 0;
}

static void
dasd_partition_destroy (PedPartition* part)
{
	PED_ASSERT(part != NULL, return);

	if (ped_partition_is_active(part))
		ped_free(part->disk_specific);
	ped_free(part);
}

static int
dasd_partition_set_flag (PedPartition* part, PedPartitionFlag flag, int state)
{
	DasdPartitionData* dasd_data;

	PED_ASSERT(part != NULL, return 0);
	PED_ASSERT(part->disk_specific != NULL, return 0);
	dasd_data = part->disk_specific;

	switch (flag) {
		case PED_PARTITION_RAID:
			if (state)
				dasd_data->lvm = 0;
			dasd_data->raid = state;
			return ped_partition_set_system(part, part->fs_type);
		case PED_PARTITION_LVM:
			if (state)
				dasd_data->raid = 0;
			dasd_data->lvm = state;
			return ped_partition_set_system(part, part->fs_type);
		default:
			return 0;
	}
}

static int
dasd_partition_get_flag (const PedPartition* part, PedPartitionFlag flag)
{
	DasdPartitionData* dasd_data;

	PED_ASSERT (part != NULL, return 0);
	PED_ASSERT (part->disk_specific != NULL, return 0);
	dasd_data = part->disk_specific;

	switch (flag) {
		case PED_PARTITION_RAID:
			return dasd_data->raid;
		case PED_PARTITION_LVM:
			return dasd_data->lvm;
		default:
			return 0;
	}
}

static int
dasd_partition_is_flag_available (const PedPartition* part,
                                  PedPartitionFlag flag)
{
	switch (flag) {
		case PED_PARTITION_RAID:
			return 1;
		case PED_PARTITION_LVM:
			return 1;
		default:
			return 0;
	}
}


static int
dasd_get_max_primary_partition_count (const PedDisk* disk)
{
	DasdDiskSpecific* disk_specific;

	disk_specific = disk->disk_specific;
	/* If formated in LDL, maximum partition number is 1 */
	if (disk_specific->format_type == 1)
		return 1;

	return USABLE_PARTITIONS;
}

static PedConstraint*
_primary_constraint (PedDisk* disk)
{
	PedAlignment start_align;
	PedAlignment end_align;
	PedGeometry	max_geom;
	PedSector sector_size;
	LinuxSpecific* arch_specific;
	DasdDiskSpecific* disk_specific;

	PDEBUG;

	arch_specific = LINUX_SPECIFIC (disk->dev);
	disk_specific = disk->disk_specific;
	sector_size = disk_specific->real_sector_size / disk->dev->sector_size;

	if (!ped_alignment_init (&start_align, 0,
							 disk->dev->hw_geom.sectors * sector_size))
		return NULL;
	if (!ped_alignment_init (&end_align, -1,
						     disk->dev->hw_geom.sectors * sector_size))
		return NULL;
	if (!ped_geometry_init (&max_geom, disk->dev, 0, disk->dev->length))
		return NULL;

	return ped_constraint_new(&start_align, &end_align, &max_geom,
							  &max_geom, 1, disk->dev->length);
}

static int
dasd_partition_align (PedPartition* part, const PedConstraint* constraint)
{
	DasdDiskSpecific* disk_specific;

	PED_ASSERT (part != NULL, return 0);

	disk_specific = part->disk->disk_specific;
	/* If formated in LDL, ignore metadata partition */
	if (disk_specific->format_type == 1)
		return 1;

	if (_ped_partition_attempt_align(part, constraint,
								     _primary_constraint(part->disk)))
		return 1;

#ifndef DISCOVER_ONLY
	ped_exception_throw (
		PED_EXCEPTION_ERROR,
		PED_EXCEPTION_CANCEL,
		_("Unable to satisfy all constraints on the partition."));
#endif

	return 0;
}

static int
dasd_partition_enumerate (PedPartition* part)
{
	int i;
	PedPartition* p;

	/* never change the partition numbers */
	if (part->num != -1)
		return 1;

	for (i = 1; i <= USABLE_PARTITIONS; i++) {
		p = ped_disk_get_partition (part->disk, i);
		if (!p) {
			part->num = i;
			return 1;
		}
	}

	/* failed to allocate a number */
	ped_exception_throw(PED_EXCEPTION_ERROR, PED_EXCEPTION_CANCEL,
						_("Unable to allocate a dasd disklabel slot"));
	return 0;
}

static int
dasd_partition_set_system (PedPartition* part,
                           const PedFileSystemType* fs_type)
{
	DasdPartitionData* dasd_data = part->disk_specific;
	PedSector cyl_size;

	cyl_size=part->disk->dev->hw_geom.sectors * part->disk->dev->hw_geom.heads;
	PDEBUG;

	part->fs_type = fs_type;

	if (dasd_data->lvm) {
		dasd_data->system = PARTITION_LINUX_LVM;
        PDEBUG;
		return 1;
	}

	if (dasd_data->raid) {
		dasd_data->system = PARTITION_LINUX_RAID;
        PDEBUG;
		return 1;
	}

	if (!fs_type) {
		dasd_data->system = PARTITION_LINUX;
        PDEBUG;
	} else if (!strcmp (fs_type->name, "linux-swap")) {
		dasd_data->system = PARTITION_LINUX_SWAP;
        PDEBUG;
	} else {
		dasd_data->system = PARTITION_LINUX;
        PDEBUG;
	}

	return 1;
}

static int
dasd_alloc_metadata (PedDisk* disk)
{
	PedPartition* new_part;
	PedConstraint* constraint_any = NULL;
	PedSector vtoc_end;
	LinuxSpecific* arch_specific;
	DasdDiskSpecific* disk_specific;

	PED_ASSERT (disk != NULL, goto error);
	PED_ASSERT (disk->dev != NULL, goto error);

	arch_specific = LINUX_SPECIFIC (disk->dev);
	disk_specific = disk->disk_specific;

	constraint_any = ped_constraint_any (disk->dev);

	/* If formated in LDL, the real partition starts at sector 24. */
	if (disk_specific->format_type == 1)
		vtoc_end = 23;
	else
        /* Mark the start of the disk as metadata. */
		vtoc_end = (FIRST_USABLE_TRK * (long long) disk->dev->hw_geom.sectors
				   * (long long) disk_specific->real_sector_size
				   / (long long) disk->dev->sector_size) - 1;

	new_part = ped_partition_new (disk,PED_PARTITION_METADATA,NULL,0,vtoc_end);
	if (!new_part)
		goto error;

	if (!ped_disk_add_partition (disk, new_part, constraint_any)) {
		ped_partition_destroy (new_part);
		goto error;
	}

	ped_constraint_destroy (constraint_any);
	return 1;

error:
	ped_constraint_destroy (constraint_any);
	return 0;
}
