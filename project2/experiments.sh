#!/bin/bash

#topologies=('line' '2D' 'full' 'imp2D')
topologies=('2D' 'imp2D')
algorithms=('gossip')

for t in "${topologies[@]}" 
do
    for a in "${algorithms[@]}" 
    do
        if [ "$t" == "line" ];
        then
            continue
        fi

        touch results/$t-$a.txt
        
        for i in {3050..4500..50}
        do
            echo $i results/$t-$a.txt
            ./project2 --numNodes $i --topology $t --algorithm $a >> results/$t-$a.txt   
        done

    done
done

