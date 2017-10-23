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
    require Heap
    use GenServer

    def start_link(args) do
        GenServer.start_link(__MODULE__, args, [{:name, {:global, args[:id]}}])
    end

    @doc """
    """
    def init(args) do      
        # create empty routing table
        num_rows = round(:math.ceil(log(args[:numNodes], 16)))
        routing_table = build_routing_table(args)
            |> add_id_to_table(args[:id], num_rows, 0)

        {:ok, %{
            :id => args[:id],
            :num_reqs => args[:numRequests],
            :map => %{},
            :routing_table => routing_table,
            :leaf_set => %{:larger => Heap.new(&(gt(&1, &2))), :smaller => Heap.new(&(lt(&1, &2)))}}} 
    end

    #################
    # API Callbacks #
    #################

    @doc """
    store a new key value pair in the node with id ~ to key
    """
    def handle_call({:store, kv}, _from, state) do
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
            :routing_table => state[:routing_table],
            :leaf_set => state[:leaf_set]}}
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
    def handle_call({:join, data}, _from, state) do  
        key = data[:key]
        path = data[:path]

        {step, next_id} = route(key, state)
         # send the step'th row of the routing table to key
         msg = %{
            :id => state[:id],
            :i => step,
            :row => state[:routing_table] |> Enum.at(step)
        }
        GenServer.cast({:global, key}, {:update_routing, msg})

        if next_id == state[:id] do
            # done routing
            # send the leaf set
            GenServer.cast({:global, key}, {:init_leaf_set, state[:leaf_set]})
            {:reply, path ++ [state[:id]], state}
        else
            Logger.debug "Forwarding from #{state[:id]} to #{next_id}"
            # pass on to the next
            new_data = %{:key => key, :path => path ++ [state[:id]]}
            reply = GenServer.call({:global, next_id}, {:join, new_data})
            {:reply, reply, state}
        end
    end

    @doc """
    Go through leaf set and routing table, sending
    everyone your id
    """
    def handle_call({:update_all_after_join}, _from, state) do
        Enum.map(state[:leaf_set][:smaller], fn id -> 
            GenServer.cast({:global, id}, {:announce_arrival, state[:id]}) end)
        Enum.map(state[:leaf_set][:larger], fn id -> 
            GenServer.cast({:global, id}, {:announce_arrival, state[:id]}) end)
        
        num_rows = length(state[:routing_table])
        
        # TODO: Only update ones not called above in leaf state!

        Enum.map(0..num_rows-1,
            fn i -> Enum.map(0..14,
                fn j -> node = state[:routing_table] |> Enum.at(i) |> Enum.at(j)
                    if node != nil and node != state[:id] do
                        GenServer.cast({:global, node}, {:announce_arrival, state[:id]})
                    end
                end)
            end)

        {:reply, state, state}
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
            :routing_table => new_table,
            :leaf_set => state[:leaf_set]}}   
    end

    @doc """
    Manually add a new id to the routing and leaf tables. Used after a join,
    before asking all nodes in state tables to update themselves
    """
    # def handle_cast({:update_entry, msg}, state) do
    #     id = msg[:id]
    #     l = shl(id, state[:id, 0]
    #     )
    #     new_table = copy_and_update(state[:routing_table],
    #         l, state[:routing_table] |> Enum.at(l), id)
        
    #     state =  %{
    #         :id => state[:id],
    #         :num_reqs => state[:num_reqs],
    #         :map => state[:map],
    #         :routing_table => new_table,
    #         :leaf_set => state[:leaf_set]}
    #     {:noreply, state}
    # end

    def handle_cast({:init_leaf_set, leaf_set}, state) do
        state =  %{
            :id => state[:id],
            :num_reqs => state[:num_reqs],
            :map => state[:map],
            :routing_table => state[:routing_table],
            :leaf_set => leaf_set}
        {:noreply, state}
    end

    @doc """
    Add the id to leaf set (if it belongs) and to the routing table, if there is room
    """
    def handle_cast({:announce_arrival, id}, state) do
        # add id to the leaf set if it is within the X smallest/largest closest - TODO
        # check the larger 
        new_leaf_set = 
          if gt(id, state[:id]) do
            new_heap = copy_and_add_heap(Heap.new(&(gt(&1, &2))), state[:leaf_set][:larger], state[:id], id, 8)
            %{:smaller => state[:leaf_set][:smaller], :larger => new_heap}
          else
            IO.puts("Updating leaf state of #{state[:id]}")
            IO.inspect(state[:leaf_set][:smaller])
            new_heap = copy_and_add_heap(Heap.new(&(lt(&1, &2))), state[:leaf_set][:smaller], state[:id], id, 8)
            %{:smaller => new_heap, :larger => state[:leaf_set][:larger]}
          end

        l = shl(id, state[:id], 0)
        new_table = copy_and_update(state[:routing_table], l,
            state[:routing_table] |> Enum.at(l), id)
        
        state =  %{
            :id => state[:id],
            :num_reqs => state[:num_reqs],
            :map => state[:map],
            :routing_table => new_table,
            :leaf_set => new_leaf_set}
        {:noreply, state}
    end

    ##############
    # Helper Fns #
    ##############
    def copy_and_add_heap(new_heap, old_heap, id, new_id, i) when i > 0 and old_heap != nil do
        if new_id != "" do
            d = dist(new_id, id)
            {root, rest} = Heap.split(old_heap)
            d2 = dist(root, id)
            if d < d2 do
                Heap.push(new_heap, new_id)
                    |> copy_and_add_heap(rest, id, "", i - 1)
            else
                Heap.push(new_heap, root) 
                    |> copy_and_add_heap(rest, id, new_id, i - 1)
            end
        else
            {root, rest} = Heap.split(old_heap)    
            Heap.push(new_heap, root) 
                |> copy_and_add_heap(rest, id, new_id, i - 1)        
        end 
    end

    def copy_and_add_heap(new_heap, _old_heap, _id, _new_id, _i) do
        new_heap
    end

    def build_routing_table(args) do
        num_rows = round(:math.ceil(log(args[:numNodes], 16)))
        num_cols = 15  # 2^b - 1
        Enum.map(0..num_rows-1,
            fn _x -> Enum.map(0..num_cols, fn _y -> nil end)
        end)         
    end

    def route(key, state) do
        IO.puts "Routing!"
        IO.inspect(key)
        IO.inspect(state)

        # first compute dist|self - key|
        dist_self = dist(key, state[:id])
        {best_lf_dist, best_lf_id} = smallest_in_leafset(key, state[:leaf_set])      
        best_l = shl(key, best_lf_id, 0)                     
        # 3 cases for leaf set
        # 1. key falls within leaf set
        #   1a. d_self < d_leafsets -> continue to routing table
        #   1b. d_leafset* < d_self -> send to d_leafset*
        # 2. key falls outside of leaf set -> proceed to routing table
        if in_leaf_set(key, state[:leaf_set]) and best_lf_dist < dist_self do
            # d_leafset* < d_self -> send to d_leafset*
            {best_l, best_lf_id}
        # check routing table
        else
            l = shl(key, state[:id], 0)            
            {d_l, _} = Integer.parse(String.at(key, l), 16)
            # check if someone with id with more digits in common 
            # exists in table
            r_d_l = state[:routing_table] |> Enum.at(l) |> Enum.at(d_l)
            
            {best_l, best_id} =
                if r_d_l != nil do
                    {l, r_d_l}
                else
                    {best_row_dist, best_row_id} = smallest_in_row(state[:id], key, state[:routing_table] |> Enum.at(l))
                    # check if the leaf set or routing table has somethign closer
                    Logger.debug "Best leaf set: #{best_lf_id}, dist: #{best_lf_dist}; best routing: #{best_row_id}, dist: #{best_row_dist}; my ID: #{state[:id]}, my dist: #{dist_self}"                    
                    cond do
                        best_lf_dist < best_row_dist and best_lf_dist < dist_self ->
                            {best_l, best_lf_id}
                        best_row_dist < best_lf_dist and best_row_dist < dist_self -> 
                            {l, best_row_id}
                        # we are the closest node
                        true ->
                            {l, state[:id]}
                    end      
                end
            {best_l, best_id}
        end
    end

    @doc """
    The length of the prefix shared among a and b, in digits
    """
    def shl(a, b, count) do
        if a == "" or b == "" do
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
        num_cols = 15
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
    
    def add_id_to_table(table, id, num_rows, i) when i < num_rows do
        copy_and_update(table, i, table |> Enum.at(i), id) 
            |> add_id_to_table(id, num_rows, i + 1)    
    end

    def add_id_to_table(table, _id, _num_rows, _i) do
        table
    end

    @doc """
    Compare two IDs by looking at the first
    8 digits (32 bits)

    returns |a' - b'|
    """
    def dist(a, b) do
        if a == nil or b == nil do
            :math.pow(2, 32)
        else
            {a_, _} = String.slice(a, 0, 8) |> Integer.parse(16)
            {b_, _} = String.slice(b, 0, 8) |> Integer.parse(16)
            abs(a_ - b_)
        end
    end

    def gt(a, b) do
        {a_, _} = String.slice(a, 0, 8)
            |> Integer.parse(16)
        {b_, _} = String.slice(b, 0, 8)
            |> Integer.parse(16)
        a_ > b_
    end

    def lt(a, b) do
        {a_, _} = String.slice(a, 0, 8)
            |> Integer.parse(16)
        {b_, _} = String.slice(b, 0, 8)
            |> Integer.parse(16)
        a_ < b_
    end

    def in_leaf_set(id, leaf_set) do
        if (Heap.size(leaf_set[:smaller]) > 0 and Heap.size(leaf_set[:larger]) > 0) and 
            (gt(Heap.root(leaf_set[:smaller]), id) or gt(id, Heap.root(leaf_set[:larger]))) do
             false
        else
            true
        end
    end

    def smallest_in_leafset(id, leaf_set) do
        # functional programming magic to compute the closest element 
        # in the leaf set to the given id
        {smallest_best, smallest_best_id} = 
            if Heap.size(leaf_set[:smaller]) > 0 do
                Enum.map(leaf_set[:smaller], fn x -> {dist(x, id), x} end)
                    |> Enum.min_by(fn {x, _} -> x end)
            else
                {:math.pow(2, 32), ""}
            end
        
        {largest_best, largest_best_id} = 
            if Heap.size(leaf_set[:larger]) > 0 do
                Enum.map(leaf_set[:larger], fn x -> {dist(x, id), x} end)
                    |> Enum.min_by(fn {x, _} -> x end)
            else
                {:math.pow(2, 32), ""}
            end

        if smallest_best <= largest_best do
            {smallest_best, smallest_best_id}
        else
            {largest_best, largest_best_id}
        end
    end

    def smallest_in_row(my_id, id, row) do
        Enum.map(row, fn x -> 
            d = 
              if x != my_id do
                dist(x, id)
              else
                :math.pow(2, 32)
              end
            {d, x}
         end) |> Enum.min_by(fn {x, _} -> x end)
    end

    

end