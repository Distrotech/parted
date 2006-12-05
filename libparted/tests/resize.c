#include <parted/parted.h>
#include <check.h>

START_TEST (test_start_sector)
{
		fail_unless(0 == 0, "Erro proposital");
}
END_TEST		

int main(void)
{
		int number_failed;
		Suite *suite = suite_create( "Resize" );
		TCase *basic = tcase_create( "Basic" );
		
		tcase_add_test( basic, test_start_sector );
		suite_add_tcase( suite, basic );

		SRunner *srunner = srunner_create( suite );
		srunner_run_all( srunner, CK_VERBOSE );

		number_failed = srunner_ntests_failed( srunner );
		srunner_free(srunner);
		
		return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}

