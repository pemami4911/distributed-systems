defmodule Pastry.Node do
    @moduledoc """
    A peer node in the Pastry overlay network
    
    sends reqs at 1 req/sec to either
    get/store a (K,V)

    The routing table has ceil(log_base16 N) rows with 
    15 entires each.

    generate nodeIDs and keys with 
        > Base.encode16(:crypto.hash(:sha, ""))
        - nodeID
        - map (K,V)
        - send routing table row
        - update routing table
        - join?
    """
    require Logger
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__, args, [{:name, {:global, args[:id]}}])
    end

    def init(args) do      
        # create empty routing table
        routing_table = build_routing_table(args)

        {:ok, %{
            :id => args[:id],
            :num_reqs => args[:numRequests],
            :map => %{},
            :routing_table => routing_table}
        } 
    end

    #######
    # API #

    @doc """
    store a new key value pair in the node with id ~ to key
    """
    def handle_call({:store, kv}, _from, state) do
        IO.puts "Storing #{kv[:key]}"
        {_, next_id} = route(kv[:key], state)
        new_map = 
          if next_id == state[:id] do
            Map.put(state[:map], kv[:key], kv[:value])
          else
            GenServer.call({:global, next_id}, {:store, kv})            
          end  
        {:reply, new_map, %{
            :id => state[:id],
            :num_reqs => state[:num_reqs],
            :map => new_map,
            :routing_table => state[:routing_table]}}
    end

    @doc """
    Retrieve the value at key "k"
    """
    def handle_call({:get, data}, _from, state) do
        key = data[:key]
        {_, next_id} = route(key, state)
        {value, hops} = 
            if next_id == state[:id] do
                {state[:map][:key], data[:hops] + 1}
            else
                GenServer.call({:global, %{:key => next_id,
                     :hops => data[:hops] + 1}}, {:get, key})
            end    
        {:reply, {value, hops}, state}
    end

    @doc """
    TODO: Getting a cycle here causing a time-out when 3 nodes with same first letter
    are in network
    """
    def handle_call({:join, key}, _from, state) do  
        {step, next_id} = route(key, state)
         # send the step'th row of the routing table to key
         msg = %{
            :id => state[:id],
            :i => step,
            :row => state[:routing_table] |> Enum.at(step)
        }
        GenServer.cast({:global, key}, {:update_routing, msg})

        # add the new one, "key", to row[step]
        new_table = copy_and_update(state[:routing_table],
             step, state[:routing_table] |> Enum.at(step), key)
        state =  %{
            :id => state[:id],
            :num_reqs => state[:num_reqs],
            :map => state[:map],
            :routing_table => new_table}

        if next_id == state[:id] do
            # done routing
            {:reply, :ok, state}
        else
            # pass on to the next
            reply = GenServer.call({:global, next_id}, {:join, key})
            {:reply, reply, state}
        end
    end

    @doc """
    Set a row of the routing table with the incoming msg
    """
    def handle_cast({:update_routing, msg}, state) do
        new_table = copy_and_update(state[:routing_table],
            msg[:i], msg[:row], msg[:id])
        {:noreply, %{
            :id => state[:id],
            :num_reqs => state[:num_reqs],
            :map => state[:map],
            :routing_table => new_table}}   
    end

    ##############
    # Helper Fns #
    def build_routing_table(args) do
        num_rows = round(:math.ceil(log(args[:numNodes], 16)))
        num_cols = 15  # 2^b - 1
        Enum.map(0..num_rows-1,
            fn _x -> Enum.map(0..num_cols, fn _y -> nil end)
        end)
    end

    def route(key, state) do
        l = shl(key, state[:id], 0)
        {d_l, _} = Integer.parse(String.at(key, l), 16)
        r_d_l = state[:routing_table] |> Enum.at(l) |> Enum.at(d_l)
        if r_d_l != nil do
            {l, r_d_l}
        else
            # we are the closest node
            {l, state[:id]}
        end
    end

    @doc """
    The length of the prefix shared among a and b, in digits
    """
    def shl(a, b, count) do
        if a == "" && b == "" do
            count
        else
            {next_a, a} = String.next_codepoint(a)
            {next_b, b} = String.next_codepoint(b)
            if next_a == next_b do
                shl(a, b, count+1)
            end
            count
        end
    end

    def log(x, b) do
        :math.log(x) / :math.log(b)
    end
    
    @doc """
    Replace the old_table[row_index] with row. 
    Place new_id at row[row_index] at the position
    indicated by the decimal value of row_index'th element
    of new_id 
    Returns the new table
    """
    def copy_and_update(old_table, row_index, row, new_id) do
        num_rows = length(old_table)
        num_cols = length(row)
        {new_id_col_idx, _} = Integer.parse(String.at(new_id, row_index), 16)
        # Iterate over the old table by element, 
        # copying over the values except for the 
        # row "row_index"
        Enum.map(0..num_rows-1,
            fn i -> Enum.map(0..num_cols-1,
                fn j -> 
                    if i == row_index do
                        if j != new_id_col_idx do
                            row |> Enum.at(j)
                        else
                            new_id
                        end
                    else
                        old_table |> Enum.at(i) |> Enum.at(j)
                    end
                end)
            end)
    end
end