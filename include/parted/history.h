/*
    libparted - a library for manipulating disk partitions
    Copyright (C) 1999, 2000, 2001, 2007 Free Software Foundation, Inc.

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

#ifndef PED_HISTORY_H_INCLUDED
#define PED_HISTORY_H_INCLUDED


/*
 * Macros
 */

#define PED_HISTORY_TAG      "[History] "
#define PED_HISTORY_MAX_NAME 64
#define PED_HISTORY_IS_UNDONE(_o) (_o->ignore && _o->disk)
        

typedef struct _PedHistObj PedHistObj;
typedef struct _PedHistManager PedHistManager;
typedef enum _PedHistRet PedHistRet;

#include <parted/disk.h>

/*
 * Enums
 */

enum _PedHistRet {
    PED_HISTORY_RET_SUCCESS,
    PED_HISTORY_RET_ERROR,
    PED_HISTORY_RET_NO_UNDO,
    PED_HISTORY_RET_NO_REDO,
    PED_HISTORY_RET_NO_SAVE,
};


/*
 * Structs
 */

struct _PedHistObj {
    int         id;
    int         ignore; /* Undo/Redo functionality */
    char       *name;   /* Command name */
    PedDisk    *disk;
    PedHistObj *prev;
    PedHistObj *next;
};


struct _PedHistManager {
    PedHistObj  *begin;
    PedHistObj  *end;
    int          n_objs;
    int          id;
};


/*
 * Funcs
 */

/* Add/Clear history */
extern void ped_history_add (const char *cmd);
extern void ped_history_clear (void);

/* Iterating */
extern const PedHistObj *ped_history_begin (void);

/* Duplicate of the most recent disk mod, this can safely be destroyed */
extern PedDisk *ped_history_disk (void);

/* Before changes are committed */
extern PedHistRet ped_history_undo (void);
extern PedHistRet ped_history_redo (void);

/* Write changes to disk
 * Each change's success/failure value is passed 
 * to the optional callback so that the end application
 * can display such values appropriately.
 */
typedef void (*PedHistPrintCB) (PedHistRet val, PedHistObj *obj);
extern PedHistRet ped_history_commit_to_disk (PedHistPrintCB cb);

/* Copy the most recent disk change */
extern void ped_history_add_disk (const PedDisk *disk);

/* Print */
extern const char *ped_history_print_ret (PedHistRet val);
extern void ped_history_print_debug (void);

/* Alloc/dealloc */
extern PedHistObj *ped_history_alloc_obj (void);
extern void ped_history_dealloc_obj (PedHistObj *obj);


#endif /* PED_HISTORY_H_INCLUDED */
