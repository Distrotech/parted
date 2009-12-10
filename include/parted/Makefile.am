if COMPILE_FOR_S390
S390_HDRS = fdasd.h vtoc.h
else
S390_HDRS =
endif

partedincludedir      =	$(includedir)/parted

partedinclude_HEADERS = constraint.h	\
			debug.h		\
			device.h	\
			disk.h		\
			exception.h	\
			filesys.h	\
			geom.h		\
			natmath.h	\
			timer.h		\
			unit.h		\
			parted.h

noinst_HEADERS	      = crc32.h		\
			endian.h	\
			$(S390_HDRS)

MAINTAINERCLEANFILES = Makefile.in
