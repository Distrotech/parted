#include <config.h>
#include <parted/parted.h>
#include <stdio.h>
#include <stdlib.h>

#include "closeout.h"

int
main (int argc, char **argv)
{
  atexit (close_stdout);

  if (argc != 2)
    return EXIT_FAILURE;

  char const *dev_name = argv[1];
  PedDevice *dev = ped_device_get (dev_name);
  if (dev == NULL)
    return EXIT_FAILURE;

  PedAlignment *pa_min = ped_device_get_minimum_alignment (dev);
  if (pa_min)
    printf ("minimum: %lld %lld\n", pa_min->offset, pa_min->grain_size);
  else
    printf ("minimum: - -\n");
  free (pa_min);

  PedAlignment *pa_opt = ped_device_get_optimum_alignment (dev);
  if (pa_opt)
    printf ("optimal: %lld %lld\n", pa_opt->offset, pa_opt->grain_size);
  else
    printf ("optimal: - -\n");
  free (pa_opt);

  ped_device_destroy (dev);

  return EXIT_SUCCESS;
}
