/*
    libparted - a library for manipulating disk partitions
    Copyright (C) 1999, 2000, 2001, 2002, 2003, 2005, 2007
                  Free Software Foundation, Inc.

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

#include <parted/parted.h>


/*
 * Macros for handling error printing
 */

char PedHistStr[32];

#define PED_HISTORY_CLR_STR() memset (PedHistStr, 0, sizeof (PedHistStr));

#define PED_HISTORY_SET_STR(_s)                    \
{                                                  \
    strncpy (PedHistStr, _s, sizeof (PedHistStr)); \
}


PedHistManager PedHistMgr = {0};


void 
ped_history_add (const char *name)
{
    PedHistObj *addme;
    size_t      name_length;

    /* Deep copy and add to end of list */
    addme = ped_history_alloc_obj ();
    addme->id = PedHistMgr.id++;

    /* Add the name using ped allocation */
    name_length = strlen (name);
    name_length = (name_length > PED_HISTORY_MAX_NAME) ?
        PED_HISTORY_MAX_NAME : name_length;
    addme->name = ped_malloc (name_length);
    strncpy (addme->name, name, name_length);
            
    /* This becomes the new end, so remember who is before us */
    addme->prev = PedHistMgr.end;

    /* Add this to the end of the list */
    if (PedHistMgr.end)
        PedHistMgr.end->next = addme;
    
    PedHistMgr.end = addme;
    
    if (!PedHistMgr.begin)
        PedHistMgr.begin = addme;
    
    PedHistMgr.n_objs++;
}


void 
ped_history_clear (void)
{
    PedHistObj *ii, *freeme;
 
    ii = PedHistMgr.begin;
    while (ii) {
        freeme = ii;
        ii = ii->next;
        ped_history_dealloc_obj (freeme);
    }

    memset (&PedHistMgr, 0, sizeof (PedHistMgr));
}


const PedHistObj *
ped_history_begin (void)
{
    return PedHistMgr.begin;
}


/* Return most recent (non-undone) disk modification */
PedDisk *
ped_history_disk (void)
{
    PedHistObj *ii;

    for (ii = PedHistMgr.end; ii; ii = ii->prev)
        if (!ii->ignore && ii->disk)
            return ped_disk_duplicate (ii->disk);

    return NULL;
}


PedHistRet 
ped_history_undo (void)
{
    PedHistObj *ii;

    /* Mark the most recent change as ignored  and that is an
     * actual 'disk' modification
     * Start with the last command issued before this 'undo' call
     */
     for (ii = PedHistMgr.end->prev; ii; ii = ii->prev)
        if (!ii->ignore && ii->disk)
            break;
 
     if (!ii)
        return PED_HISTORY_RET_NO_UNDO;

     ii->ignore = 1;
     return PED_HISTORY_RET_SUCCESS;
}

    
PedHistRet 
ped_history_redo (void)
{
    PedHistObj *ii;

    /* Find the most recent undone entry that is a 'disk' mod */
    for (ii = PedHistMgr.begin; ii; ii = ii->next)
        if (ii->ignore && ii->disk)
            break;

    if (!ii)
        return PED_HISTORY_RET_NO_REDO;

    ii->ignore = 0;
    return PED_HISTORY_RET_SUCCESS;
}


PedHistObj *
ped_history_alloc_obj (void)
{
    PedHistObj *obj = (PedHistObj *)ped_calloc (sizeof (PedHistObj));
    return obj;
}


void 
ped_history_dealloc_obj (PedHistObj *obj)
{
    if (!obj)
        return;

    if (obj->disk)
        ped_disk_destroy (obj->disk);
  
    ped_free (obj->name);
    ped_free (obj);
}


PedHistRet 
ped_history_commit_to_disk (PedHistPrintCB cb)
{
    int         has_commit;
    PedHistObj *ii;

    has_commit = 0;
    for (ii = PedHistMgr.begin; ii; ii = ii->next) {
        if (ii->disk && !ii->ignore) {
            has_commit = 1;
            if (ped_disk_commit (ii->disk) && cb)
                cb (PED_HISTORY_RET_SUCCESS, ii);
            else if (cb)
                cb (PED_HISTORY_RET_ERROR, ii);
        }
    }
  
    /* Restart fresh */
    ped_history_clear ();

    if (!has_commit)
        return PED_HISTORY_RET_NO_SAVE;

    return PED_HISTORY_RET_SUCCESS;
} 


void
ped_history_add_disk (const PedDisk *disk)
{
    PedHistMgr.end->disk = ped_disk_duplicate (disk); 
}


/* Print all history objects */
void 
ped_history_print_debug (void)
{
    int         has_history;
    PedHistObj *ii;

    has_history = 0; 
    for (ii = PedHistMgr.begin; ii; ii = ii->next) {

        /* Only print disk changes */
        if (!ii->disk)
            continue;
        
        has_history = 1; 
        printf ("[History]\t");
    
        if (ii->ignore)
            printf (" (UNDONE)");
    }

    if (!has_history)
        printf (PED_HISTORY_TAG "No history available\n");
}


const char *
ped_history_print_ret (PedHistRet val)
{
    switch (val)
    {
        case PED_HISTORY_RET_ERROR: 
            PED_HISTORY_SET_STR ("unknown error");
            break;

        case PED_HISTORY_RET_NO_UNDO:
            PED_HISTORY_SET_STR ("could not undo");
            break;
        
        case PED_HISTORY_RET_NO_REDO:
            PED_HISTORY_SET_STR ("could not redo");
            break;
        
        case PED_HISTORY_RET_NO_SAVE:
            PED_HISTORY_SET_STR ("nothing to save");
            break;

        default: PED_HISTORY_CLR_STR ();
            break;
    }

    return PedHistStr;
}
