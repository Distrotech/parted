ZARCH = $(shell uname -m 2>/dev/null | tr [A-Z] [a-z] | sed -e 's/s390x/s390/g)

S390_HDRS =
ifeq ($(ZARCH),s390)
S390_HDRS = fdasd.h vtoc.h
endif

partedincludedir      =	$(includedir)/parted

partedinclude_HEADERS = gnu.h		\
			linux.h		\
			constraint.h	\
			debug.h		\
			device.h	\
			disk.h		\
			exception.h	\
			filesys.h	\
			geom.h		\
			natmath.h	\
			timer.h		\
			unit.h		\
			parted.h        \
			$(S390_HDRS)

noinst_HEADERS	      = crc32.h		\
			endian.h

MAINTAINERCLEANFILES = Makefile.in
