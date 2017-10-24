# Pastry

Team: Patrick Emami - UFID: 70923125

## What's Working 

I implemented the route and join methods from the Pastry paper for a Distributed Hash Table. I chose to implement a simple get/store application that fills the DHT
with N items. Each node in the network makes M reqs at 1/sec for a random item out of the N.

The largest network I tried it on was 2000 nodes. The average hops per item retrieval is printed out as a result. I noticed that some queries (1-5% fail), so the average hops number is slightly optimistic. These failures seem to rarely occur when a key value is passed through the routing of the DHT and arrives at a node with very similar ID, but without the key in its key/value store and without any closer nodes in its leaf set or routing table. Investigating these edge cases is left for future work.

## Installation

I am using the [heap](https://github.com/jamesotron/heap) Elixir package, which can be installed with Hex:

  `mix deps.get`

Then, to build, do: 

  `mix escript.build` 

## Running

  `./project3 --numNodes 1000 --numRequests 5`

## Example output

./project3 --numNodes 2000 --numRequests 5

16:07:04.268 [info]  Finished building DHT

16:07:04.270 [info]  Started gather GenServer

16:07:05.028 [info]  Finished storing items in DHT

16:07:05.099 [info]  [6] sending 5 queries to the DHT from 2000 peers...

16:07:06.143 [info]  [5] sending 5 queries to the DHT from 2000 peers...

16:07:07.143 [info]  [4] sending 5 queries to the DHT from 2000 peers...

16:07:08.159 [info]  [3] sending 5 queries to the DHT from 2000 peers...

16:07:09.159 [info]  [2] sending 5 queries to the DHT from 2000 peers...

16:07:10.160 [info]  [1] sending 5 queries to the DHT from 2000 peers...

16:07:11.191 [info]  average hops per item retrieval: ~3.79. Log(2000) = 7.6

