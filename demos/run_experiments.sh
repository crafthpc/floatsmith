#/usr/bin/env bash

ROOT=$(pwd)
REGEN="no"

APPS="sanity axpy sum2pi_x arclength"
STRATEGIES="compositional simple_comp ddebug"
GROUPINGS=("" "-g typechain:cluster")

echo "AppName,BaselineTime,NumCandidates,ADAPT,ADAPTChanges,Strategy,Group,MergeGroups,Tested,Aborted,Failed,Passed,MaxReplaced,BestSpeedup" | tee $ROOT/experiment.out

for app in $APPS; do
    cd $ROOT/$app
    invoke=$(grep "floatsmith -B" run.sh)
    if [ -n "$(echo $invoke | grep -e '--adapt')" ]; then
        invoke=$(echo $invoke | sed -e 's/--adapt//')
        ADAPT_FLAGS=("" "--adapt")
    else
        ADAPT_FLAGS=("")
    fi
    for adapt in "${ADAPT_FLAGS[@]}"; do
        for strat in $STRATEGIES; do
            for grp in "${GROUPINGS[@]}"; do
                tag=$(echo ".fs-${strat}${grp}" | sed -e 's/[^A-Za-z0-9._-]/_/g')

                if [ "$REGEN" = "yes" ] || [ ! -e $tag ]; then
                    rm -rf $tag
                    mkdir $tag
                    #echo "$invoke --root $tag $adapt -s $strat $grp"
                    $invoke --root $tag $adapt -s $strat $grp -J slurm &>$tag/floatsmith.log
                fi

                if [ -e $tag ]; then
                    $ROOT/../scripts/summ_experiment.sh $tag | tee -a $ROOT/experiment.out
                fi
            done
        done
    done
done
