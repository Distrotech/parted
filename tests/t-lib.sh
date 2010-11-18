# source this file; set up for tests

# Copyright (C) 2009-2010 Free Software Foundation, Inc.

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

# Skip this test if the shell lacks support for functions.
unset function_test
eval 'function_test() { return 11; }; function_test'
if test $? != 11; then
  echo "$0: /bin/sh lacks support for functions; skipping this test." 1>&2
  Exit 77
fi

skip_()
{
  echo "$0: skipping test: $@" | head -1 1>&9
  echo "$0: skipping test: $@" 1>&2
  Exit 77
}

fail_()
{
  echo "$0: failed test: $@" | head -1 1>&9
  echo "$0: failed test: $@" 1>&2
  Exit 1
}

# We use a trap below for cleanup.  This requires us to go through
# hoops to get the right exit status transported through the signal.
# So use `Exit STATUS' instead of `exit STATUS' inside of the tests.
# Turn off errexit here so that we don't trip the bug with OSF1/Tru64
# sh inside this function.
Exit ()
{
  set +e
  (exit $1)
  exit $1
}

test_dir_=$(pwd)

this_test_() { echo "./$0" | sed 's,.*/,,'; }
this_test=$(this_test_)

# This is a stub function that is run upon trap (upon regular exit and
# interrupt).  Override it with a per-test function, e.g., to unmount
# a partition, or to undo any other global state changes.
cleanup_() { :; }

t_=$(mktemp -d --tmp="$test_dir_" pe-$this_test.XXXXXXXXXX)\
    || error_ "failed to create temporary directory in $test_dir_"

# Eval the following upon cleanup.
# This is useful if you have more than than one cleanup function,
# and for encapsulated cleanup functions; append any addition.
cleanup_eval_=':'

remove_tmp_()
{
  __st=$?
  cleanup_
  test -n "$cleanup_eval_" && eval "$cleanup_eval_"
  cd "$test_dir_" && chmod -R u+rwx "$t_" && rm -rf "$t_" && exit $__st
}

. $srcdir/t-local.sh
. $srcdir/t-lib-helpers.sh

# Run each test from within a temporary sub-directory named after the
# test itself, and arrange to remove it upon exception or normal exit.
trap remove_tmp_ 0
trap 'Exit $?' 1 2 13 15

cd "$t_" || error_ "failed to cd to $t_"

if ( diff --version < /dev/null 2>&1 | grep GNU ) 2>&1 > /dev/null; then
  compare() { diff -u "$@"; }
elif ( cmp --version < /dev/null 2>&1 | grep GNU ) 2>&1 > /dev/null; then
  compare() { cmp -s "$@"; }
else
  compare() { cmp "$@"; }
fi
