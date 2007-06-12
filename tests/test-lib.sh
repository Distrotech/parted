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

# Avoid spurious test failures due to buggy ncurses-5.6.
unset TERM

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

this_test_() { expr "./$0" : '.*/\(t[0-9]*\)-[^/]*$'; }

test "${test_description}" != "" ||
error "Test script did not set test_description."

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
	this_test=$(this_test_)
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

this_test=$(this_test_)

skip_=0
# If $privileges_required_ is nonempty, non-root skips this test.
if test "$privileges_required_" != ''; then
    uid=`id -u` || error 'failed to run "id -u"'
    if test "$uid" != 0; then
	SKIP_TESTS="$SKIP_TESTS $this_test"
	say "you have insufficient privileges for test $this_test"
	skip_=1
    fi
fi

emit_superuser_warning()
{
  uid=`id -u` || uid=1
  test "$uid" != 0 &&
    echo 'WARNING: You are not superuser.  Watch out for permissions.' || :
}

# Test the binaries we have just built.
pwd_=`pwd`
parted_="$pwd_/../parted/parted"

test_dir_=$PARTED_USABLE_TEST_DIR
test $test_dir_ = . && test_dir_=$pwd_

fail=
# Some tests require an actual hardware device, e.g., a real disk with a
# spindle, a USB key, or a CD-RW.  If this variable is nonempty, the user
# has properly set the $DEVICE_TO_ERASE and $DEVICE_TO_ERASE_SIZE envvars,
# then the test will proceed.  Otherwise, it is skipped.
if test $skip_ = 0 && test "$erasable_device_required_" != ''; then
  # Since testing a drive with parted destroys all data on that drive,
  # we have rather draconian safety requirements that should help avoid
  # accidents.  If $dev_ is the name of the device,
  # - running "parted -s $dev_ print" must succeed, and
  # - its output must include a line matching /^Disk $dev_: $DEV_SIZE$/
  # - Neither $dev_ nor any $dev_[0-9]* may be mounted.
  if test "$DEVICE_TO_ERASE" != '' && test "$DEVICE_TO_ERASE_SIZE" != ''; then
    dev_=$DEVICE_TO_ERASE
    sz=$DEVICE_TO_ERASE_SIZE
    parted_output=$($parted_ -s $dev_ print) || fail="no such device: $dev_"
    $parted_ -s $dev_ print|grep "^Disk $dev_: $sz$" \
	> /dev/null || fail="actual device size is not $sz"
    # Try to see if $dev_ or any of its partitions is mounted.
    # This is not reliable.  FIXME: find a better way.
    # Maybe expose parted's own test for whether a disk is in use.
    # The following assume that $dev_ is canonicalized, e.g., that $dev_
    # contains no "//" or "/./" components.

    # Prefer df --local, if it works, so we don't waste time
    # enumerating lots of automounted file systems.
    ( df --local / > /dev/null 2>&1 ) && df='df --local' || df=df
    $df | grep "^$dev_" && fail="$dev_ is already mounted"
    $df | grep "^$dev_[0-9]" && fail="a partition of $dev_ is already mounted"

    # Skip this test and complain if anything failed.
    if test "$fail" != ''; then
      SKIP_TESTS="$SKIP_TESTS $this_test"
      say "invalid setup: $fail"
    fi
  else
    # Skip quietly if both envvars are not specified.
    SKIP_TESTS="$SKIP_TESTS $this_test"
    say 'This test requires an erasable device and you have not properly'
    say 'set the $DEVICE_TO_ERASE and $DEVICE_TO_ERASE_SIZE envvars.'
  fi
fi

# This is a stub function that is run upon trap (upon regular exit and
# interrupt).  Override it with a per-test function, e.g., to unmount
# a partition, or to undo any other global state changes.
cleanup_() { :; }

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
		trap - exit
		test_done
	esac
done

t0=$($abs_top_srcdir/tests/mkdtemp $test_dir_ parted-$this_test.XXXXXXXXXX) \
    || error "failed to create temporary directory in $test_dir_"

# Run each test from within a temporary sub-directory named after the
# test itself, and arrange to remove it upon exception or normal exit.
trap 'st=$?; cleanup_; d='"$t0"';
    cd '"$test_dir_"' && chmod -R u+rwx "$d" && rm -rf "$d" && exit $st' 0
trap '(exit $?); exit $?' 1 2 13 15

cd $t0 || error "failed to cd to $t0"

if ( diff --version < /dev/null 2>&1 | grep GNU ) 2>&1 > /dev/null; then
  compare='diff -u'
elif ( cmp --version < /dev/null 2>&1 | grep GNU ) 2>&1 > /dev/null; then
  compare='cmp -s'
else
  compare=cmp
fi
