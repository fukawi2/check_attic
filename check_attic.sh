#!/bin/bash

###############################################################################
# Copyright (C) 2010-2011 Phillip Smith
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################

set -e
set -u

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

function usage() {
  echo "$PROGNAME -p /path/to/attic/repo [-w warning_age] [-c critical_age]"
  echo
  echo 'Time periods are in MINUTES"'
}

function exit_ok() {
  echo "OK: $1"
  exit 0
}
function exit_warning() {
  echo "WARNING: $1"
  exit 1
}
function exit_critical() {
  echo "CRITICAL: $1"
  exit 2
}
function exit_unknown() {
  echo "UNKNOWN: $1"
  exit 3
}

function main() {
  # defaults to be overridden by command line args below
  local attic_repo=
  local -i age_warn=3600   # 3600 = 24 hours
  local -i age_crit=10800  # 10800 = 3 Days

  export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

  ### get command line args
  while getopts “hw:c:p:” OPTION ; do
    case $OPTION in
    h)
      usage
      exit -1
      ;;
    p)
      attic_repo="$OPTARG"
      ;;
    w)
      age_warn="$OPTARG"
      ;;
    c)
      age_crit="$OPTARG"
      ;;
    ?)
      usage
      exit -1
      ;;
    esac
  done

  ### check command line args
  if [[ ! -n "$attic_repo" ]] ; then
    usage
    exit -1
  fi

  ### can we find the 'attic' command?
  hash attic 2>/dev/null || { echo 'attic binary not found!'; exit -1; }

  #TODO: export ATTIC_PASSPHRASE=
  
  ### make sure at least one backup has been made
  local archive_cnt=$(attic list "$attic_repo" | wc -l)
  if [[ $archive_cnt -lt 1 ]] ; then
    exit_critical 'No archives found in repository!'
  fi

  ### find the last archive timestamp and calcuate difference in seconds, then
  ### convert to minutes and evaluate
  local last_attic_archive=$(attic list "$attic_repo" | awk 'END{ $1=""; print $0 }')
  local tz_now=$(date +%s)
  local tz_then=$(date -d "$last_attic_archive" +%s)
  diff_secs=$(($tz_now-$tz_then))
  diff_mins=$(($diff_secs / 60))

  if [[ $diff_mins -gt $age_crit ]] ; then
    # Way too old
    exit_critical "Last backup was $diff_mins minutes ago"
  elif [[ $diff_mins -gt $age_warn ]] ; then
    # Too old
    exit_warning "Last backup was $diff_mins minutes ago"
  else
    exit_ok "Last backup was $diff_mins minutes ago"
  fi
}
main $ARGS

exit 0

###############################################################################
# FUNCTIONS
###############################################################################

function bomb {
	# Error handling; Yay!
	echo "BOMBS AWAY: $1" > &2
	exit 1;
}

function warn() {
	# Show warning to user
	echo "WARNING: $1" > &2
}

function dbg {
	# Debug Helper
	echo "DEBUG: $1" > &2
}

sub usage {
	echo "Usage: $0 [options]\n";
	echo "Options:\n";
	printf "   %-25s %-50s\n", '--opta', 'Enables Option A';
	printf "   %-25s %-50s\n", '--optb', 'Enables Option B';
	printf "   %-25s %-50s\n", '--optc', 'Enables Option C';
}
