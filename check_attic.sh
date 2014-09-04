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
  echo "$PROGNAME /path/to/attic/repo [warning_age] [critical_age]"
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
  local attic_repo="${1:-}"

  ### check command line args
  if [[ ! -n "$attic_repo" ]] ; then
    usage
    exit_unknown 'Invalid command'
  fi
  local age_warn=${2:-3600}   # 3600 = 24 hours
  local age_crit=${3:-10800}  # 10800 = 3 Days

  #TODO: export ATTIC_PASSPHRASE=
  
  ### make sure at least one backup has been made
  local archive_cnt=$(attic list "$attic_repo" | wc -l)
  if [[ $archive_cnt -lt 1 ]] ; then
    exit_critical 'No archives found in repository!'
  fi

  ### find the last archive timestamp and calcuate difference in seconds, then
  ### convert to minutes and evaluate
  local last_attic_archive=$(attic list "$attic_repo" | awk '{ tz=$2 } END{ print $tz }')
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
