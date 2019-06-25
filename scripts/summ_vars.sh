#!/usr/bin/env bash
#
# Summarize results from dump_vars.rb; produces a reverse-sorted frequency map
# of variables replaced in any JSON files passed in.
#

SCRIPT_DIR=$(dirname $(readlink -e ${BASH_SOURCE[0]}))
$SCRIPT_DIR/dump_vars.rb $@ | sort | uniq -c | sort -n

