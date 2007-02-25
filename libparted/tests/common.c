#include <config.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>

#include "common.h"


char *_create_disk(const off_t size)
{
		char filename[] = "parted-test-XXXXXX";
		mktemp(filename);

		FILE *disk = fopen(filename, "w");
		off_t total_size = size * 1024 * 1024; /* Mb */

		fseek(disk, total_size, SEEK_SET);
		fwrite("", sizeof(char), sizeof(char), disk);
		fclose(disk);

		return strdup(filename);
}
