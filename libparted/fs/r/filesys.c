/* libparted - a library for manipulating disk partitions
    Copyright (C) 1999-2001, 2007-2011 Free Software Foundation, Inc.

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

/** \file filesys.c */

/**
 * \addtogroup PedFileSystem
 *
 * \note File systems exist on a PedGeometry - NOT a PedPartition.
 *
 * @{
 */

#include <config.h>

#include <parted/parted.h>
#include <parted/debug.h>

#if ENABLE_NLS
#  include <libintl.h>
#  define _(String) dgettext (PACKAGE, String)
#else
#  define _(String) (String)
#endif /* ENABLE_NLS */

/**
 * This function opens the file system stored on \p geom, if it
 * can find one.
 * It is often called in the following manner:
 * \code
 *     fs = ped_file_system_open (&part.geom)
 * \endcode
 *
 * \throws PED_EXCEPTION_ERROR if file system could not be detected
 * \throws PED_EXCEPTION_ERROR if the file system is bigger than its volume
 * \throws PED_EXCEPTION_NO_FEATURE if opening of a file system stored on
 *     \p geom is not implemented
 *
 * \return a PedFileSystem on success, \c NULL on failure.
 */
PedFileSystem *
ped_file_system_open (PedGeometry* geom)
{
       PedFileSystem*          fs;
       PedGeometry*            probed_geom;

       PED_ASSERT (geom != NULL);

       if (!ped_device_open (geom->dev))
               goto error;

       PedFileSystemType *type = ped_file_system_probe (geom);
       if (!type) {
               ped_exception_throw (PED_EXCEPTION_ERROR, PED_EXCEPTION_CANCEL,
                                    _("Could not detect file system."));
               goto error_close_dev;
       }

       probed_geom = ped_file_system_probe_specific (type, geom);
       if (!probed_geom)
               goto error_close_dev;
       if (!ped_geometry_test_inside (geom, probed_geom)) {
               if (ped_exception_throw (
                       PED_EXCEPTION_ERROR,
                       PED_EXCEPTION_IGNORE_CANCEL,
                       _("The file system is bigger than its volume!"))
                               != PED_EXCEPTION_IGNORE)
                       goto error_destroy_probed_geom;
       }

       if (!type->ops->open) {
               ped_exception_throw (PED_EXCEPTION_NO_FEATURE,
                                    PED_EXCEPTION_CANCEL,
                                    _("Support for opening %s file systems "
                                      "is not implemented yet."),
                                    type->name);
               goto error_destroy_probed_geom;
       }

       fs = type->ops->open (probed_geom);
       if (!fs)
               goto error_destroy_probed_geom;
       ped_geometry_destroy (probed_geom);
       return fs;

error_destroy_probed_geom:
       ped_geometry_destroy (probed_geom);
error_close_dev:
       ped_device_close (geom->dev);
error:
       return NULL;
}

/**
 * Close file system \p fs.
 *
 * \return \c 1 on success, \c 0 on failure
 */
int
ped_file_system_close (PedFileSystem* fs)
{
       PedDevice*      dev = fs->geom->dev;

       PED_ASSERT (fs != NULL);

       if (!fs->type->ops->close (fs))
               goto error_close_dev;
       ped_device_close (dev);
       return 1;

error_close_dev:
       ped_device_close (dev);
       return 0;
}

/**
 * Resize \p fs to new geometry \p geom.
 *
 * \p geom should satisfy the ped_file_system_get_resize_constraint().
 * (This isn't asserted, so it's not a bug not to... just it's likely
 * to fail ;)  If \p timer is non-NULL, it is used as the progress meter.
 *
 * \throws PED_EXCEPTION_NO_FEATURE if resizing of file system \p fs
 *     is not implemented yet
 *
 * \return \c 0 on failure
 */
int
ped_file_system_resize (PedFileSystem* fs, PedGeometry* geom, PedTimer* timer)
{
       PED_ASSERT (fs != NULL);
       PED_ASSERT (geom != NULL);

       if (!fs->type->ops->resize) {
               ped_exception_throw (PED_EXCEPTION_NO_FEATURE,
                                    PED_EXCEPTION_CANCEL,
                                    _("Support for resizing %s file systems "
                                      "is not implemented yet."),
                                    fs->type->name);
               return 0;
       }
       if (!fs->checked && fs->type->ops->check) {
               if (!ped_file_system_check (fs, timer))
                       return 0;
       }
       if (!ped_file_system_clobber_exclude (geom, fs->geom))
               return 0;

       return fs->type->ops->resize (fs, geom, timer);
}
