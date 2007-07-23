/*
    libparted - a library for manipulating disk partitions
    Copyright (C) 2005, 2007 Free Software Foundation, Inc.

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
*/

#include <config.h>

#include <parted/parted.h>
#include <parted/endian.h>
#include <parted/debug.h>

#if ENABLE_NLS
#  include <libintl.h>
#  define _(String) dgettext (PACKAGE, String)
#else
#  define _(String) (String)
#endif /* ENABLE_NLS */

#include <unistd.h>

#include "bfs.h"


#define BFS_SPECIFIC(fs) ((struct BfsSpecific*) (fs->type_specific))
#define BFS_SB(fs)       (BFS_SPECIFIC(fs)->sb)


const char BFS_MAGIC[4] = { 0x1B, 0xAD, 0xFA, 0xCE };
const long long BFS_SECTOR_SIZE         = 512;
const uint32_t  BFS_PED_SANITY          = 0xffffffff;
const long long BFS_PED_MIN_INODES      = 16;

static PedGeometry*
bfs_probe (PedGeometry* geom)
{
	uint8_t*        buf;

        PED_ASSERT (geom      != NULL, return NULL);
        PED_ASSERT (geom->dev != NULL, return NULL);

        buf = ped_malloc (geom->dev->sector_size);
        
	if (!ped_geometry_read (geom, buf, 0, 1))
		return 0;

        //if ( PED_CPU_TO_LE32((uint32_t)buf) == BFS_MAGIC )
		return ped_geometry_new (geom->dev, geom->start,
                                ped_div_round_up (
                                        PED_CPU_TO_LE32((uint32_t)(buf+8)),
                                        geom->dev->sector_size));
	else
		return NULL;
}

#ifndef DISCOVER_ONLY
static int
bfs_clobber (PedGeometry* geom)
{
	uint8_t*  buf;

        PED_ASSERT (geom      != NULL, return 0);
        PED_ASSERT (geom->dev != NULL, return 0);

        buf = ped_malloc (geom->dev->sector_size);
        
        if (!ped_geometry_read (geom, buf, 0, 1))
                return 0;
	memset (buf, 0, 512);
	return ped_geometry_write (geom, buf, 0, 1);
}
#endif /* !DISCOVER_ONLY */


static PedFileSystem*
bfs_alloc (const PedGeometry* geom)
{
	PedFileSystem*  fs;

	fs = (PedFileSystem*) ped_malloc (sizeof (PedFileSystem));
	if (!fs)
		goto error;

	fs->type_specific = (struct BfsSpecific*) ped_malloc (
                        sizeof (struct BfsSpecific));
	if (!fs->type_specific)
		goto error_free_fs;

	fs->geom = ped_geometry_duplicate (geom);
	if (!fs->geom)
		goto error_free_type_specific;

	fs->checked = 0;
	return fs;

error_free_type_specific:
	ped_free (fs->type_specific);
error_free_fs:
	ped_free (fs);
error:
	return NULL;
}


void
bfs_free (PedFileSystem* fs)
{
        ped_geometry_destroy (fs->geom);
        ped_free (fs->type_specific);
        ped_free (fs);
}


static PedFileSystem* 
bfs_open (PedGeometry *geom)
{
        PedFileSystem* fs = bfs_alloc (geom);
        
        struct bfs_sb* sb = (struct bfs_sb*) ped_malloc(sizeof(struct bfs_sb));
        struct BfsSpecific* bfs;
        uint8_t* buf;
       
        PED_ASSERT (geom      != NULL, return NULL);
        PED_ASSERT (geom->dev != NULL, return NULL);
        
        buf = ped_malloc (geom->dev->sector_size);
        
        if (!fs)
                return NULL;

        bfs = fs->type_specific;
        
        if (!ped_geometry_read (geom, buf, 0, 1))
                return NULL;
        
        memcpy (sb, buf, BFS_SECTOR_SIZE);
                        
        bfs->sb = sb;

        return fs;
}


#ifndef DISCOVER_ONLY
static struct bfs_inode* create_root_inode()
{
        struct bfs_inode* root = ped_malloc (sizeof(struct bfs_inode));

        root->i = 2UL;
        /*root->start = FIX;
        root->end = ;
        root->eof_off = ;*/
        root->attr = 2UL;
        root->mode = 512UL; /* rwxrwxrwx */
        root->uid = root->gid = 0UL;
        root->nlinks = 0UL;
        root->atime = root->ctime = 0UL;
        memset ((void*)root->reserved, 0, 32*4);
        
        return root;
}


static uint8_t* _block_alloc (int n)
{
        return ped_calloc (n * BFS_SECTOR_SIZE);
}


static void _write_inodes (PedFileSystem* fs)
{
}


/* write a BFS block - always 512 bytes */
static int _write_block (PedFileSystem* fs, uint8_t* buf, int n)
{
        /* FIXME: support for bs != 2^9 */
        return ped_geometry_write ( fs->geom, buf, n, 1 );
}


static int _write_sb (PedFileSystem* fs)
{
        uint8_t* sb = _block_alloc (1);
        
        BFS_SB(fs)->magic  = BFS_MAGIC;
        BFS_SB(fs)->sanity = BFS_PED_SANITY;
        BFS_SB(fs)->start  = BFS_SPECIFIC(fs)->data_start;
        BFS_SB(fs)->size   = BFS_SPECIFIC(fs)->size;
        
        memcpy (sb, BFS_SB(fs), sizeof(struct bfs_sb));

        return _write_block (fs, sb, 1);
}


static PedFileSystem* 
bfs_create (PedGeometry *geom, PedTimer *timer)
{
        PedFileSystem* fs = bfs_alloc (geom);
        int n_inodes = PED_MAX (BFS_PED_MIN_INODES, 16/*some sane value here*/);
        
        /* TODO: check whether geometry is big enough */
        
        fs->data_start = 1 + ped_round_up_to (n_inodes * 64, 512);
        fs->size = geom->dev->sector_size * length;
        
        ped_timer_set_state_name (timer, "Writing inodes"); 
        
       
        
        ped_timer_set_state_name (timer, "Writing super block");
        _write_sb (fs);
                
        return 0; 
}
#endif /* !DISCOVER_ONLY */


static PedFileSystemOps bfs_ops = {
	probe:		bfs_probe,
#ifndef DISCOVER_ONLY
	clobber:	bfs_clobber,
#else
	clobber:	NULL,
#endif 
	open:		bfs_open,
#ifndef DISCOVER_ONLY
	create:		bfs_create,
#else
        create:         NULL
#endif
	close:		NULL,
	check:		NULL,
	copy:		NULL,
	resize:		NULL,
	get_create_constraint:	NULL,
	get_resize_constraint:	NULL,
	get_copy_constraint:	NULL
};

static PedFileSystemType bfs_type = {
	next:	        NULL,
	ops:	        &bfs_ops,
	name:	        "bfs",
        block_sizes:    ((int[2]){512, 0})
};

void
ped_file_system_bfs_init ()
{
	ped_file_system_type_register (&bfs_type);
}

void
ped_file_system_bfs_done ()
{
	ped_file_system_type_unregister (&bfs_type);
}


