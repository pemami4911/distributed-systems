# Pastry

Team: Patrick Emami

## What's Working 

I implemented the route and join methods from the paper. I implemented a simple "get" and "store" for the DHT. When testing, I run into a few bugs still, but I have verified that it is mostly working. 

## Installation

I am using the [heap](https://github.com/jamesotron/heap) Elixir package, which can be installed with 

  `mix deps.get`

Then, just do 

  `mix escript.build` 

## Running

  `./project3 --numNodes X --numRequests Z`

The largest network I managed to deal with was 1000 nodes. It has a few bugs still which causes it to crash- I am still trying to debug them. I observed that even for 1000 nodes, it takes only 2-4 hops to find the value.

