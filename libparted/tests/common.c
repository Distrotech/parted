#include <config.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>

#include "common.h"

char *_create_disk (const off_t size)
{
        char *filename = strdup ("parted-test-XXXXXX");

        if (filename == NULL)
                return NULL;

        int fd = mkstemp (filename);
        if (fd < 0) {
        free_filename:
                free (filename);
                return NULL;
        }

        FILE *disk = fdopen (fd, "w");
        if (disk == NULL)
                goto free_filename;

        off_t total_size = size * 1024 * 1024;	/* Mb */

        int fail = (fseek (disk, total_size, SEEK_SET) != 0
                    || fwrite ("", sizeof (char), 1, disk) != 1);

        if (fclose (disk) != 0 || fail)
                goto free_filename;

        return filename;
}
