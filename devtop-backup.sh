#!/usr/bin/env bash
# =============================================================================
# Copyright       : LICENSE.md
# Contributing    : CONTRIBUTING.md
# 
# =============================================================================

##############################################
# 
# Welcome to the mac developer backup/syc script!
# This script helps the user to backup or sync 
# SRC to DEST (currently on local directory or mount supported)
# Example Use Case:
# 1) Want to backup data (exact copy) of laptop data to a usb drive. 
##############################################

#----------------------------------------------
# Configure the shell
#----------------------------------------------
# Some specific hygine settings to configure the shell
shopt -s extglob
set -o errtrace
set -o errexit
# shellcheck disable=SC2154
trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT
# Die on failures
set -e


CMDNAME=`basename $0`
#----------------------------------------------
# Init all variables used
#----------------------------------------------
#dry run is turned off by default, unless user specifies -n in command.
DRY_RUN=''
SOURCE=$HOME/
HOST_NAME=`hostname`
MC_NAME=`echo ${HOST_NAME//./_}`
TARGET="/Volumes/sg_01t_bk_0/$MC_NAME/$USER/"
EXCLUDES="$HOME/laptop/exclude-sync-list.txt"
GLOBAL_FILTERS="$HOME/.rsync/global-filters"
# For debug purpose only.
#EXCLUDES="./exclude-sync-list.txt"
#GLOBAL_FILTERS="./dotfiles/rsync/global-filters"


while getopts n OPT
do
  case $OPT in
    "n" ) DRY_RUN="--dry-run" ;;
      * ) echo "Usage: $CMDNAME [-n]" 1>&2
          exit 1 ;;
  esac
done

#----------------------------------------------
# Validate all conditions, pre-requisites before sync
#----------------------------------------------
validate_before_run(){
  echo "Validating all conditions before run ......"
  if [ ! -r "$SOURCE" ]; then
    MESSAGE="Source $SOURCE not readable - Cannot start the sync process"
    echo $MESSAGE
    exit;
  fi
  #[[ ! -d $TARGET ]] && echo "Target directory does NOT exists." && exit 1
  if [ ! -d "$TARGET" ]; then
    echo "Target $TARGET directory does NOT exists. Will attempt to create one ..."
    mkdir -p "$TARGET"
  elif [ ! -w "$TARGET" ]; then
    MESSAGE="Destination $TARGET not writeable - Cannot start the sync process"
    echo $MESSAGE
    exit;
  fi

}


add_sync_options(){
  echo "Adding sync options ..."
  #TODO: explain the options choosen and what they will do
  #  -v, --verbose               increase verbosity
  #  -q, --quiet                 suppress non-error messages
  #  -c, --checksum              skip based on checksum, not mod-time & size
  #  -a, --archive               archive mode; same as -rlptgoD (no -H)
  #      --no-OPTION             turn off an implied OPTION (e.g. --no-D)
  #  -r, --recursive             recurse into directories
  #  -R, --relative              use relative path names
  #      --no-implied-dirs       don’t send implied dirs with --relative
  #  -b, --backup                make backups (see --suffix & --backup-dir)
  #      --backup-dir=DIR        make backups into hierarchy based in DIR
  #      --suffix=SUFFIX         backup suffix (default ~ w/o --backup-dir)
  #  -u, --update                skip files that are newer on the receiver
  #      --inplace               update destination files in-place
  #      --append                append data onto shorter files
  #  -d, --dirs                  transfer directories without recursing
  #  -l, --links                 copy symlinks as symlinks
  #  -L, --copy-links            transform symlink into referent file/dir
  #      --copy-unsafe-links     only "unsafe" symlinks are transformed
  #      --safe-links            ignore symlinks that point outside the tree
  #  -k, --copy-dirlinks         transform symlink to dir into referent dir
  #  -K, --keep-dirlinks         treat symlinked dir on receiver as dir
  #  -H, --hard-links            preserve hard links
  #  -p, --perms                 preserve permissions
  #  -E, --executability         preserve executability
  #  -A, --acls                  preserve ACLs (implies -p) [non-standard]
  #  -X, --xattrs                preserve extended attrs (implies -p) [n.s.]
  #      --chmod=CHMOD           change destination permissions
  #  -o, --owner                 preserve owner (super-user only)
  #  -g, --group                 preserve group
  #      --devices               preserve device files (super-user only)
  #      --specials              preserve special files
  #  -D                          same as --devices --specials
  #  -t, --times                 preserve times
  #  -O, --omit-dir-times        omit directories when preserving times
  #      --super                 receiver attempts super-user activities
  #  -S, --sparse                handle sparse files efficiently
  #  -n, --dry-run               show what would have been transferred
  #  -W, --whole-file            copy files whole (without rsync algorithm)
  #  -x, --one-file-system       don’t cross filesystem boundaries
  #  -B, --block-size=SIZE       force a fixed checksum block-size
  #  -e, --rsh=COMMAND           specify the remote shell to use
  #      --rsync-path=PROGRAM    specify the rsync to run on remote machine
  #      --existing              ignore non-existing files on receiving side
  #      --ignore-existing       ignore files that already exist on receiver
  #      --remove-sent-files     sent files/symlinks are removed from sender
  #      --del                   an alias for --delete-during
  #      --delete                delete files that don’t exist on sender
  #      --delete-before         receiver deletes before transfer (default)
  #      --delete-during         receiver deletes during xfer, not before
  #      --delete-after          receiver deletes after transfer, not before
  #      --delete-excluded       also delete excluded files on receiver
  #      --ignore-errors         delete even if there are I/O errors
  #      --force                 force deletion of dirs even if not empty
  #      --max-delete=NUM        don’t delete more than NUM files
  #      --max-size=SIZE         don’t transfer any file larger than SIZE
  #      --min-size=SIZE         don’t transfer any file smaller than SIZE
  #      --partial               keep partially transferred files
  #      --partial-dir=DIR       put a partially transferred file into DIR
  #      --delay-updates         put all updated files into place at end
  #  -m, --prune-empty-dirs      prune empty directory chains from file-list
  #      --numeric-ids           don’t map uid/gid values by user/group name
  #      --timeout=TIME          set I/O timeout in seconds
  #  -I, --ignore-times          don’t skip files that match size and time
  #      --size-only             skip files that match in size
  #      --modify-window=NUM     compare mod-times with reduced accuracy
  #  -T, --temp-dir=DIR          create temporary files in directory DIR
  #  -y, --fuzzy                 find similar file for basis if no dest file
  #      --compare-dest=DIR      also compare received files relative to DIR
  #      --copy-dest=DIR         ... and include copies of unchanged files
  #      --link-dest=DIR         hardlink to files in DIR when unchanged
  #  -z, --compress              compress file data during the transfer
  #      --compress-level=NUM    explicitly set compression level
  #  -C, --cvs-exclude           auto-ignore files in the same way CVS does
  #  -f, --filter=RULE           add a file-filtering RULE
  #  -F                          same as --filter=’dir-merge /.rsync-filter’
  #                              repeated: --filter=’- .rsync-filter’
  #      --exclude=PATTERN       exclude files matching PATTERN
  #      --exclude-from=FILE     read exclude patterns from FILE
  #      --include=PATTERN       don’t exclude files matching PATTERN
  #      --include-from=FILE     read include patterns from FILE
  #      --files-from=FILE       read list of source-file names from FILE
  #  -0, --from0                 all *from/filter files are delimited by 0s
  #      --address=ADDRESS       bind address for outgoing socket to daemon
  #      --port=PORT             specify double-colon alternate port number
  #      --sockopts=OPTIONS      specify custom TCP options
  #      --blocking-io           use blocking I/O for the remote shell
  #      --stats                 give some file-transfer stats
  #  -8, --8-bit-output          leave high-bit chars unescaped in output
  #  -h, --human-readable        output numbers in a human-readable format
  #      --progress              show progress during transfer
  #  -P                          same as --partial --progress
  #  -i, --itemize-changes       output a change-summary for all updates
  #      --log-format=FORMAT     output filenames using the specified format
  #      --password-file=FILE    read password from FILE
  #      --list-only             list the files instead of copying them
  #      --bwlimit=KBPS          limit I/O bandwidth; KBytes per second
  #      --write-batch=FILE      write a batched update to FILE
  #      --only-write-batch=FILE like --write-batch but w/o updating dest
  #      --read-batch=FILE       read a batched update from FILE
  #      --protocol=NUM          force an older protocol version to be used
  #      --checksum-seed=NUM     set block/file checksum seed (advanced)
  #  -4, --ipv4                  prefer IPv4
  #  -6, --ipv6                  prefer IPv6
  #      --version               print version number
  # (-h) --help                  show this help (see below for -h comment)


  # PLEASE DON'T CHANGE THE ORDER OF THE SYNC_OPTS
  # Beware that the options should go in the right order
  SYNC_OPTS="-vvaE -S --progress --human-readable --stats"
  #merge the global filters
  if [ ! -f "$GLOBAL_FILTERS" ]; then
      echo "Skipping user home directory merge filter, $GLOBAL_FILTERS not present  ..."
    else
      #File present, add the filter
      #SYNC_OPTS="$SYNC_OPTS --filter=\". $GLOBAL_FILTERS\""
      echo ""
  fi

  #merge any filters in directory of source
  if [ ! -f "$HOME/.rsync-filters" ]; then
      echo "Skipping source directory merge filter, rsync-filter file not present ..."
    else
      #File present, add the filter
      SYNC_OPTS="$SYNC_OPTS --filter=': /.rsync-filters'"
  fi
  #Specify the excludes if any
  #SYNC_OPTS="$SYNC_OPTS --exclude-from='$EXCLUDES'"

  # Add dry run flag if user opted for it.
  SYNC_OPTS="$SYNC_OPTS $DRY_RUN"
}

validate_before_run
add_sync_options
echo "Start sync .......... "
echo "Settings: .........."
echo "SYNC_OPTS=$SYNC_OPTS"
echo "SOURCE=$SOURCE"
echo "TARGET=$TARGET"
echo "Command to run: rsync $SYNC_OPTS --filter=\". $GLOBAL_FILTERS\" --exclude-from=$EXCLUDES ${SOURCE} ${TARGET}"
echo "===================================================================="
#rsync -r -t -v --progress --exclude-from=${EXCLUDE-LIST} $DRY_RUN \
#rsync -r -t -v -P --exclude-from=${EXCLUDES} $DRY_RUN ${SOURCE} ${TARGET}
#TODO: when filter is part of SYNC_OPTS, rsync throws error
rsync $SYNC_OPTS --filter=". $GLOBAL_FILTERS" --exclude-from="$EXCLUDES" "${SOURCE}" "${TARGET}"
echo "===================================================================="
echo "End sync !!!!!!!!! "
