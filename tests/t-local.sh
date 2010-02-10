# Put test-related bits that are parted-specific here.
# This file is sourced from near the end of t-lib.sh.
sector_size_=${PARTED_SECTOR_SIZE:-512}

scsi_debug_lock_file_="$abs_srcdir/scsi_debug.lock"

require_scsi_debug_module_()
{
  # check for scsi_debug module
  modprobe -n scsi_debug ||
    skip_test_ "you lack the scsi_debug kernel module"
}

scsi_debug_modprobe_succeeded_=
cleanup_eval_="$cleanup_eval_; scsi_debug_cleanup_"
scsi_debug_cleanup_()
{
  rm -f $scsi_debug_lock_file_
  test -z "$scsi_debug_modprobe_succeeded_" && return

  # We have to insist.  Otherwise, a single rmmod usually fails to remove it,
  # due either to "Resource temporarily unavailable" or to
  # "Module scsi_debug is in use".
  for i in 1 2 3; do rmmod scsi_debug && break; sleep .2 || sleep 1; done
}

# Helper function: wait 2s (via .1s increments) for FILE to appear.
# Usage: wait_for_dev_to_appear_ /dev/sdg
# Return 0 upon success, 1 upon failure.
wait_for_dev_to_appear_()
{
  local file=$1
  local i=0
  local incr=1
  while :; do
    ls "$file" > /dev/null 2>&1 && return 0
    sleep .1 2>/dev/null || { sleep 1; incr=10; }
    i=$(expr $i + $incr); test $i = 20 && break
  done
  return 1
}

# Tests that uses "modprobe scsi_debug ..." must not be run in parallel.
scsi_debug_acquire_lock_()
{
  local retries=20
  local lock_timeout_seconds=120
  lockfile -1 -r $retries -l $lock_timeout_seconds $scsi_debug_lock_file_
}

print_sd_names_() { (cd /sys/block && printf '%s\n' sd*); }

# Create a device using the scsi_debug module with the options passed to
# this function as arguments.  Upon success, print the name of the new device.
scsi_debug_setup_()
{
  scsi_debug_acquire_lock_

  # It is not trivial to determine the name of the device we're creating.
  # Record the names of all /sys/block/sd* devices *before* probing:
  print_sd_names_ > before
  modprobe scsi_debug "$@" || { rm -f before; return 1; }
  scsi_debug_modprobe_succeeded_=1

  # Wait up to 2s (via .1s increments) for the list of devices to change.
  # Sleeping for a fraction of a second requires GNU sleep, so fall
  # back on sleeping 2x1s if that fails.
  # FIXME-portability: using "cmp - ..." probably requires GNU cmp.
  local incr=1
  local i=0
  while print_sd_names_ | cmp -s - before; do
    sleep .1 2>/dev/null || { sleep 1; incr=10; }
    i=$(expr $i + $incr); test $i = 20 && break
  done

  # Record the names of all /sys/block/sd* devices *after* probe+wait.
  print_sd_names_ > after

  # Determine which device names (if any) are new.
  # There could be more than one new device, and there have been a removal.
  local new_dev=$(comm -13 before after)
  rm -f before after
  case $new_dev in
    sd[a-z]) ;;
    sd[a-z][a-z]) ;;
    *) return 1 ;;
  esac
  local t=/dev/$new_dev
  wait_for_dev_to_appear_ $t
  echo $t
  return 0
}

require_512_byte_sector_size_()
{
  test $sector_size_ = 512 \
      || skip_test_ FS test with sector size != 512
}

peek_()
{
  case $# in 2) ;; *) echo "usage: peek_ FILE 0_BASED_OFFSET" >&2; exit 1;; esac
  case $2 in *[^0-9]*) echo "peek_: invalid offset: $2" >&2; exit 1 ;; esac
  dd if="$1" bs=1 skip="$2" count=1
}

poke_()
{
  case $# in 3) ;; *) echo "usage: poke_ FILE 0_BASED_OFFSET BYTE" >&2; exit 1;;
    esac
  case $2 in *[^0-9]*) echo "poke_: invalid offset: $2" >&2; exit 1 ;; esac
  case $3 in ?) ;; *) echo "poke_: invalid byte: '$3'" >&2; exit 1 ;; esac
  printf %s "$3" | dd of="$1" bs=1 seek="$2" count=1 conv=notrunc
}

# byte 56 of the partition entry is the first byte of its 72-byte name field
gpt1_pte_name_offset_()
{
  local ss=$1
  case $ss in *[^0-9]*) echo "$0: invalid sector size: $ss">&2; return 1;; esac
  expr $ss \* 2 + 56
  return 0
}

# Change the name of the first partition in the primary GPT table,
# thus invalidating the PartitionEntryArrayCRC32 checksum.
gpt_corrupt_primary_table_()
{
  case $# in 2) ;; *) echo "$0: expected 2 args, got $#" >&2; return 1;; esac
  local dev=$1
  local ss=$2
  case $ss in *[^0-9]*) echo "$0: invalid sector size: $ss">&2; return 1;; esac

  # get the first byte of the name
  local orig_pte_name_byte=$(peek_ $dev $(gpt1_pte_name_offset_ $ss)) || return 1

  local new_byte
  test x"$orig_pte_name_byte" = xA && new_byte=B || new_byte=A

  # Replace with a different byte
  poke_ $dev $(gpt1_pte_name_offset_ $ss) "$new_byte" || return 1

  printf %s "$orig_pte_name_byte"
  return 0
}

gpt_restore_primary_table_()
{
  case $# in 3) ;; *) echo "$0: expected 2 args, got $#" >&2; return 1;; esac
  local dev=$1
  local ss=$2
  case $ss in *[^0-9]*) echo "$0: invalid sector size: $ss">&2; return 1;; esac
  local orig_byte=$3
  poke_ $dev $(gpt1_pte_name_offset_ $ss) "$orig_byte" || return 1
}

. $srcdir/t-lvm.sh
