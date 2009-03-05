#!/bin/sh

#set -x

SRCDIR=.
FTPURL=ftp://ftp-upload.gnu.org/incoming/ftp/
NOUPLOAD=no

case $1 in
	-a|--alpha)
		FTPURL=ftp://ftp-upload.gnu.org/incoming/alpha/ ;;
	-n|--noupload)
		NOUPLOAD=yes ;;
	-?|--help)
		echo "Upload tarball to ftp.gnu.org"
		echo "Usage: $(basename $0) [option]"
		echo "Options:"
		echo "   -a, --alpha     Upload to alpha.gnu.org"
		echo "   -n, --noupload  Do all steps except upload via FTP"
		echo "   -?, --help      Display usage screen"
		exit 0 ;;
esac

cd $SRCDIR

# release GNU Parted (without tagging).
# (C)2005, 2006 Leslie Patrick Polzer <polzer@gnu.org>
# Modified by David Cantrell <dcantrell@gnu.org>

message() {
	echo '====================================================='
	echo "$1"
	echo '====================================================='
}

correct_version() {
	grep $1 $2  >/dev/null
	if [ $? -eq 0 ]; then
		return 0
	fi
	return 1
}

check_for_program() {
	which $1
	if [ $? -ne 0 ]; then
		echo "not found, exiting."
		exit
	fi
}

echo "* checking for programs that might be missing..."
for p in sha1sum gpg curl git; do
	echo -en "\t$p: "
	check_for_program $p
done

if [ -x ./bootstrap ]; then
	./bootstrap
else
	exit 1
fi

if [ -x ./configure ]; then
	./configure
else
	exit 1
fi

message "* generating ChangeLog"
( GIT_DIR=.git git-log > .changelog.tmp && \
  mv .changelog.tmp ChangeLog ; \
  rm -f .changelog.tmp \
) || \
( touch ChangeLog ; \
  echo 'git directory not found: installing possibly empty changelog.' \
)

VERSION=$(grep ' VERSION' lib/config.h | awk '{print $3}' | tr -d '"')

message "* checking for correct version in files"
for f in NEWS; do
	echo -n -e "\t$f: "
	correct_version $VERSION $f
	if [ $? -eq 0 ]; then
		echo OK
	else
		echo "-> WARNING: version mismatch"
	fi
done

correct_version $VERSION Doxyfile
if [ $? -ne 0 ]; then
	echo "-> WARNING: version not updated in Doxygen configuration!"
fi

message '* checking whether code compiles: '
make -s
if [ $? -ne 0 ]; then
	echo no; exit
fi
echo OK

# FIXME
# echo "running regression tests"

message 'RELEASE SANITY TESTS SUCCESSFULLY FINISHED!
I hope you tagged the release beforehand!
Hit <RETURN> to continue with "make dist".'
read

message '* creating tarballs...'
for f in gzip bzip2; do
	echo -n "dist-$f: "
	make dist-$f
	if [ $? -ne 0 ]; then
		echo FAILED; exit
	fi
	echo success
done

set -x
# set up gpg-agent
GPGAENV=$(gpg-agent --daemon -s)
GPGAPID=$(echo $GPGAENV | cut -d ':' -f 2)
eval "$GPGAENV"
set +x

for EXT in gz bz2; do
	TARBALL=parted-$VERSION.tar.$EXT
	SHA1FILE=$TARBALL.sha1

	message "* signing $TARBALL to detached signature file $TARBALL.sig"
	gpg --use-agent -b $TARBALL
	if [ $? -ne 0 ]; then
		kill $GPGAPID echo "\t-> FAILED"; exit
	fi
	echo -e "\t-> success"

	sha1sum $TARBALL > $SHA1FILE
	message "* signing $SHA1FILE to detached signature file $SHA1FILE.sig"
	gpg --use-agent -b $SHA1FILE
	if [ $? -ne 0 ]; then
		kill $GPGAPID echo "\t-> FAILED"; exit
	fi
	echo -e "\t-> success"

	for FILE in $TARBALL $SHA1FILE; do
		DIRECTIVE=$FILE.directive
		message "* creating and clearsigning directive file to $DIRECTIVE.asc"
		echo "version: 1.1" > $DIRECTIVE
		echo "directory: parted" >> $DIRECTIVE
		echo "filename: $FILE" >> $DIRECTIVE
		if [ $? -ne 0 ]; then
			kill $GPGAPID; echo creation FAILED; exit
		fi
		echo -e "\t-> created "
		gpg --use-agent --clearsign $DIRECTIVE
		if [ $? -ne 0 ]; then
			kill $GPGAPID; echo ", but signing failed"; exit
		fi
		echo -e "\t-> signed"

		message "* deleting $DIRECTIVE."
		rm $DIRECTIVE
	done

	#kill $GPGAPID
done

message "! Ready! Hit <RETURN> to start upload."
read

message "* uploading files to ftp-upload.gnu.org..."
for EXT in gz bz2; do
	T=parted-$VERSION.tar.$EXT
	TSIG=$TARBALL.sig
	TDIR=$TARBALL.directive.asc

	S=$TARBALL.sha1
	SSIG=$SHA1FILE.sig
	SDIR=$SHA1FILE.directive.asc

	for f in $T $TSIG $TDIR $S $SSIG $SDIR; do
		if [ "$NOUPLOAD" = "yes" ]; then
			echo "-> skipping upload of $f"
			continue
		fi
		curl --upload-file $PWD/$f $FTPURL
		sleep 1
		if [ $? -eq 0 ]; then
			echo "-> successfully uploaded $f."
		else
			echo "-> upload of $f FAILED, exiting."
		fi
		sleep 1
	done
done

message "* all files uploaded."
