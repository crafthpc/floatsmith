#/usr/bin/env bash
#

TESTS="sanity axpy sum2pi_x arclength"
LOGFILE="floatsmith.log"

echo "" >$LOGFILE
for t in $TESTS; do
    echo "Running $t (output in $t/$LOGFILE)"
    ( cd $t && ./run.sh &>$LOGFILE )
    echo >>$LOGFILE
    echo "====  $t  ====" >>$LOGFILE
    echo >>$LOGFILE
    cat $t/$LOGFILE >>$LOGFILE
done

echo "Done. Full output is located in $LOGFILE."

