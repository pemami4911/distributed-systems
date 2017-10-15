defmodule Pastry.Node do
    @moduledoc """
    A peer node in the Pastry overlay network
    sends reqs at 1 req/sec

    generate nodeIDs and keys with 
        > Base.encode16(:crypto.hash(:sha, ""))

        - left neighbor
        - right neighbor
        - finger table
            - leaf set
            - routing table
        - nodeID
        - map (K,V)
        - app
        - send leaf set
        - send routing table row
        - update leaf set
        - update routing table
        - join?
    """
    use GenServer
end