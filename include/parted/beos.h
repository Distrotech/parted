/*
    libparted - a library for manipulating disk partitions
    Copyright (C) 2006, 2007 Free Software Foundation, Inc.

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

#ifndef PED_BEOS_H_INCLUDED
#define PED_BEOS_H_INCLUDED

#include <parted/parted.h>
#include <parted/device.h>

#define BEOS_SPECIFIC(dev)	((BEOSSpecific*) (dev)->arch_specific)

typedef	struct _BEOSSpecific	BEOSSpecific;

struct _BEOSSpecific {
	int	fd;
};

extern PedArchitecture ped_beos_arch;

#endif /* PED_LINUX_H_INCLUDED */

