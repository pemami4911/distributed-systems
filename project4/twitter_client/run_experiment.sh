#!/bin/bash

CFG_DIR="lib/sim/cfg/"
#EXPERIMENTS=("conn" "topk" "tps_stress" "user_stress")
EXPERIMENTS=("topk")

for i in "${EXPERIMENTS[@]}"
do
    for filename in $CFG_DIR$i/*.txt;
    do
        ../twitter_engine/twitter_engine &
        sleep 3
        echo "starting experiment $filename..."
        ./twitter_client --config $filename        
        pid=`ps -fu $USER | grep twitter_engine | grep -v "grep" | awk '{ print $2 }'`
        kill $pid
        sleep 3
    done 
done

