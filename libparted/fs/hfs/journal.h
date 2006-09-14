/*
    libparted - a library for manipulating disk partitions
    Copyright (C) 2004 Free Software Foundation, Inc.

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

#ifndef _JOURNAL_H
#define _JOURNAL_H

#include <parted/parted.h>
#include <parted/endian.h>
#include <parted/debug.h>

#include "hfs.h"

int
hfsj_replay_journal(PedFileSystem* fs);

int
hfsj_update_jib(PedFileSystem* fs, uint32_t block);

int
hfsj_update_jl(PedFileSystem* fs, uint32_t block);

#endif /* _JOURNAL_H */
