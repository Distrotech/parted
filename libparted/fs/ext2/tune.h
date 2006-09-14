/*
    tune.h -- ext2 tunables header
    Copyright (C) 1998-2000 Free Software Foundation, Inc.
  
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
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#ifndef _TUNE_H
#define _TUNE_H

#define MAXCONT  256

extern int ext2_buffer_cache_pool_size;
extern int ext2_hash_bits;
extern int ext2_max_groups;
extern int ext2_relocator_pool_size;

#endif
