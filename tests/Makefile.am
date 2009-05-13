TESTS = \
  t0000-basic.sh \
  t0100-print.sh \
  t0200-gpt.sh \
  t0201-gpt.sh \
  t1000-mkpartfs.sh \
  t1100-busy-label.sh \
  t1500-small-ext2.sh \
  t1700-ext-probe.sh \
  t2000-mkfs.sh \
  t2100-mkswap.sh \
  t2200-dos-label-recog.sh \
  t3000-constraints.sh \
  t3100-resize-ext2-partion.sh \
  t4000-sun-raid-type.sh \
  t4100-msdos-partition-limits.sh \
  t4100-dvh-partition-limits.sh \
  t4100-msdos-starting-sector.sh \
  t4200-partprobe.sh \
  t5000-tags.sh \
  t6000-dm.sh \
  t7000-scripting.sh \
  t8000-loop.sh

EXTRA_DIST = \
  $(TESTS) test-lib.sh lvm-utils.sh

parted_dir = $(abs_top_builddir)/parted
pp_dir = $(abs_top_builddir)/partprobe
sep = $(PATH_SEPARATOR)

CLEANFILES = init.sh
all: init.sh
init.sh: Makefile.in
	rm -f $@-t $@
	echo 'PARTED_USABLE_TEST_DIR=$(PARTED_USABLE_TEST_DIR)' > $@-t
	echo 'abs_top_srcdir=$(abs_top_srcdir)' >> $@-t
	echo 'PATH=$(parted_dir)$(sep)$(pp_dir)$(sep)$$PATH' >> $@-t
	echo 'export PATH' >> $@-t
	chmod a-w $@-t
	mv $@-t $@

TESTS_ENVIRONMENT =	\
  srcdir='$(srcdir)'	\
  ENABLE_DEVICE_MAPPER=$(ENABLE_DEVICE_MAPPER)
