#include <config.h>
#include <unistd.h>

#include <check.h>

#include <parted/parted.h>

#include "common.h"

static char *temporary_disk;

static void create_disk(void)
{
		temporary_disk = _create_disk(20);
		fail_if(temporary_disk == NULL,
                        "Failed to create temporary disk");
}

static void destroy_disk(void)
{
		unlink(temporary_disk);
		free(temporary_disk);
}

/* TEST: Create a disklabel on a simple disk image */
START_TEST (test_create_label)
{
		PedDevice *dev = ped_device_get(temporary_disk);
		PedDiskType *type;
		PedDisk *disk;

		for (type = ped_disk_type_get_next(NULL); type;
			 type = ped_disk_type_get_next(type)) {

				/* Not implemented yet */
				if (strncmp(type->name, "aix", 3) == 0)
						continue;

				disk = ped_disk_new_fresh(dev, type);
				fail_if(!disk, "Failed to create a label of type: %s",
						 type->name);
		}
}
END_TEST

int main(void)
{
		int number_failed;
		Suite *suite = suite_create("Disk Label");
		TCase *tcase_basic = tcase_create("Create");

		tcase_add_checked_fixture(tcase_basic, create_disk, destroy_disk);
		tcase_add_test(tcase_basic, test_create_label);
		suite_add_tcase(suite, tcase_basic);

		SRunner *srunner = srunner_create(suite);
		srunner_run_all(srunner, CK_VERBOSE);

		number_failed = srunner_ntests_failed(srunner);
		srunner_free(srunner);

		return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
