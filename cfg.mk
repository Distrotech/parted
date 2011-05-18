# Customize maint.mk                           -*- makefile -*-
# Copyright (C) 2003-2011 Free Software Foundation, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Use alpha.gnu.org for alpha and beta releases.
# Use ftp.gnu.org for stable releases.
gnu_ftp_host-alpha = alpha.gnu.org
gnu_ftp_host-beta = alpha.gnu.org
gnu_ftp_host-stable = ftp.gnu.org
gnu_rel_host = $(gnu_ftp_host-$(RELEASE_TYPE))

url_dir_list = \
  ftp://$(gnu_rel_host)/gnu/parted

# Used in maint.mk's web-manual rule
manual_title = Parted User's Manual

# Tests not to run as part of "make distcheck".
# Exclude changelog-check here so that there's less churn in ChangeLog
# files -- otherwise, you'd need to have the upcoming version number
# at the top of the file for each `make distcheck' run.
local-checks-to-skip = \
  sc_error_message_uppercase \
  sc_error_message_period \
  sc_file_system \
  sc_prohibit_strcmp \
  sc_prohibit_atoi_atof \
  sc_require_test_exit_idiom \
  sc_space_tab \
  sc_texinfo_acronym

# Now that we have better (check.mk) tests, make this the default.
export VERBOSE = yes

old_NEWS_hash = 31d7ac1051f7d5678928cb459b7abd5f

include $(srcdir)/dist-check.mk

useless_free_options = \
  --name=pth_free

# Tools used to bootstrap this package, used for "announcement".
bootstrap-tools = autoconf,automake,gettext,gnulib,gperf

update-copyright-env = \
  UPDATE_COPYRIGHT_USE_INTERVALS=1 \
  UPDATE_COPYRIGHT_MAX_LINE_LENGTH=79

#==> .j/.x-sc_GPL_version <==
#build-aux/vc-list-files

exclude_file_name_regexp--sc_bindtextdomain = ^(libparted/)?tests/.*\.c$$

exclude_file_name_regexp--sc_cross_check_PATH_usage_in_tests = \
  ^libparted/tests/t.*\.sh$$

exclude_file_name_regexp--sc_prohibit_always-defined_macros = \
  ^parted/(strlist|table)\.h$$
