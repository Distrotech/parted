#!/bin/sh
# Derived from git's t/test-lib.sh.
# Copyright (c) 2005 Junio C Hamano

# For repeatability, reset the environment to known value.
LANG=C
LC_ALL=C
TZ=UTC
export LANG LC_ALL TZ

# Protect ourselves from common misconfiguration to export
# CDPATH into the environment
unset CDPATH

# Each test should start with something like this, after copyright notices:
#
# test_description='Description of this test...
# This test checks if command xyzzy does the right thing...
# '
# . ./test-lib.sh

error () {
	echo "* error: $*"
	trap - exit
	exit 1
}

say () {
	echo "* $*"
}

test "${test_description}" != "" ||
error "Test script did not set test_description."

# If $srcdir is not set, set it, if it's ".".  Otherwise, fail.
if test -a "$srcdir"; then
    if test -f test-lib.sh; then
	srcdir=.
    else
	error '$srcdir is not set; either set it, or run the test' \
	    'from the source directory'
    fi
fi

while test "$#" -ne 0
do
	case "$1" in
	-d|--d|--de|--deb|--debu|--debug)
		debug=t; shift ;;
	-i|--i|--im|--imm|--imme|--immed|--immedi|--immedia|--immediat|--immediate)
		immediate=t; shift ;;
	-h|--h|--he|--hel|--help)
		echo "$test_description"
		exit 0 ;;
	-v|--v|--ve|--ver|--verb|--verbo|--verbos|--verbose)
		verbose=t; shift ;;
	esac
done

exec 5>&1
if test "$verbose" = "t"
then
	exec 4>&2 3>&1
else
	exec 4>/dev/null 3>/dev/null
fi

test_failure=0
test_count=0

trap 'echo >&5 "FATAL: Unexpected exit with code $?"; exit 1' exit

# You are not expected to call test_ok_ and test_failure_ directly, use
# the text_expect_* functions instead.

test_ok_ () {
	test_count=$(expr "$test_count" + 1)
	say "  ok $test_count: $@"
}

test_failure_ () {
	test_count=$(expr "$test_count" + 1)
	test_failure=$(expr "$test_failure" + 1);
	say "FAIL $test_count: $1"
	shift
	echo "$@" | sed -e 's/^/	/'
	test "$immediate" = "" || { trap - exit; exit 1; }
}

test_debug () {
	test "$debug" = "" || eval "$1"
}

test_run_ () {
	eval >&3 2>&4 "$1"
	eval_ret="$?"
	return 0
}

test_skip () {
	this_test=$(expr "./$0" : '.*/\(t[0-9]*\)-[^/]*$')
	this_test="$this_test.$(expr "$test_count" + 1)"
	to_skip=
	for skp in $SKIP_TESTS
	do
		case "$this_test" in
		$skp)
			to_skip=t
		esac
	done
	case "$to_skip" in
	t)
		say >&3 "skipping test: $@"
		test_count=$(expr "$test_count" + 1)
		say "skip $test_count: $1"
		: true
		;;
	*)
		false
		;;
	esac
}

test_expect_failure () {
	test "$#" = 2 ||
	error "bug in the test script: not 2 parameters to test-expect-failure"
	if ! test_skip "$@"
	then
		say >&3 "expecting failure: $2"
		test_run_ "$2"
		if [ "$?" = 0 -a "$eval_ret" != 0 -a "$eval_ret" -lt 129 ]
		then
			test_ok_ "$1"
		else
			test_failure_ "$@"
		fi
	fi
	echo >&3 ""
}

test_expect_success () {
	test "$#" = 2 ||
	error "bug in the test script: not 2 parameters to test-expect-success"
	if ! test_skip "$@"
	then
		say >&3 "expecting success: $2"
		test_run_ "$2"
		if [ "$?" = 0 -a "$eval_ret" = 0 ]
		then
			test_ok_ "$1"
		else
			test_failure_ "$@"
		fi
	fi
	echo >&3 ""
}

test_expect_code () {
	test "$#" = 3 ||
	error "bug in the test script: not 3 parameters to test-expect-code"
	if ! test_skip "$@"
	then
		say >&3 "expecting exit code $1: $3"
		test_run_ "$3"
		if [ "$?" = 0 -a "$eval_ret" = "$1" ]
		then
			test_ok_ "$2"
		else
			test_failure_ "$@"
		fi
	fi
	echo >&3 ""
}

test_done () {
	case "$test_failure" in
	0)
		# We could:
		# cd .. && rm -fr trash
		# but that means we forbid any tests that use their own
		# subdirectory from calling test_done without coming back
		# to where they started from.
		# The Makefile provided will clean this test area so
		# we will leave things as they are.

		say "passed all $test_count test(s)"
		exit 0 ;;

	*)
		say "failed $test_failure among $test_count test(s)"
		exit 1 ;;

	esac
}

pwd_=`pwd`

# Test the binaries we have just built.  The tests are kept in
# t/ subdirectory and are run in trash subdirectory.
PATH=$pwd_/../parted:$PATH
export PATH

t0=`echo "$0"|sed 's,.*/,,'`.tmp; tmp_=$t0/$$
trap 'st=$?; cd "$pwd_" && chmod -R u+rwx $t0 && rm -rf $t0 && exit $st' 0
trap '(exit $?); exit $?' 1 2 13 15

framework_failure=0
mkdir -p $tmp_ || framework_failure=1
cd $tmp_ || framework_failure=1
test $framework_failure = 0 \
     || error 'failed to create temporary directory'

this_test=$(expr "./$0" : '.*/\(t[0-9]*\)-[^/]*$')
for skp in $SKIP_TESTS
do
	to_skip=
	for skp in $SKIP_TESTS
	do
		case "$this_test" in
		$skp)
			to_skip=t
		esac
	done
	case "$to_skip" in
	t)
		say >&3 "skipping test $this_test altogether"
		say "skip all tests in $this_test"
		test_done
	esac
done

if ( diff --version < /dev/null 2>&1 | grep GNU ) 2>&1 > /dev/null; then
  compare='diff -u'
elif ( cmp --version < /dev/null 2>&1 | grep GNU ) 2>&1 > /dev/null; then
  compare='cmp -s'
else
  compare=cmp
fi
