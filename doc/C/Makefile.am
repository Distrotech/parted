## Process this file with automake to produce Makefile.in

dist_man_MANS = \
	parted.8 \
	partprobe.8

man_MANS = $(dist_man_MANS)

.PHONY: updatepo
# Update the POT in srcdir
# Make sure the update does not only consist in a new POT-Creation-Date
updatepo:
	cd $(srcdir); \
	for name in $(dist_man_MANS); do \
		echo $$name; \
		cp po/$$name.pot po/$$name.new.pot; \
		po4a-updatepo -f man -m $$name -p po/$$name.new.pot; \
		diff -I '^\"POT-Creation-Date: ' po/$$name.pot po/$$name.new.pot 2>&1 > /dev/null; \
		if [ $$? ]; then \
			mv po/$$name.new.pot po/$$name.pot; \
		else \
			rm -f po/$$name.new.pot; \
		fi; \
	done

dist-hook: updatepo
