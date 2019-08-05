#!/usr/bin/env bash

path=$1
tag=$(basename $PWD)
baseline=$(grep -e '"runtime"' $path/search/baseline/*.json | cut -f 4 -d '"')
candidates=$(dump_vars.rb $path/typeforge_vars.json | wc -l)
if [ -e $path/adapt_recommend.json ]; then
    adapt="adapt"
    adapt_replace=$(dump_vars.rb $path/adapt_recommend.json | wc -l)
else
    adapt="noadapt"
    adapt_replace="0"
fi
strategy=$(grep strategy_name $path/search/craft.settings | cut -f 2 -d '=')
group=$(grep group_by_labels $path/search/craft.settings | cut -f 2 -d '=')
if [ "yes" == "$(grep merge_overlapping $path/search/craft.settings | cut -f 2 -d '=')" ]; then
    merge="merge"
else
    merge="nomerge"
fi
cd $path/search
tested=$(craft status  | grep "configs tested"   | cut -f 2 -d ':' | tr -d ' ')
aborted=$(craft status | grep "Total aborted"    | cut -f 2 -d ':' | tr -d ' ')
failed=$(craft status  | grep "Total failed"     | cut -f 2 -d ':' | tr -d ' ')
passed=$(craft status  | grep "Total passed"     | cut -f 2 -d ':' | tr -d ' ')
speedup=$(craft status | grep "Speedup achieved" | cut -f 2 -d ":" | cut -f 1 -d 'x' | tr -d ' \n')
maxrepl=$( (for i in passed/*; do echo "$(dump_vars.rb $i | wc -l) $i"; done) | sort -n | tail -n 1 | cut -f 1 -d ' ')

echo "$tag,$baseline,$candidates,$adapt,$adapt_replace,$strategy,$group,$merge,$tested,$aborted,$failed,$passed,$maxrepl,$speedup"

