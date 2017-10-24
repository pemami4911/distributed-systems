defmodule Pastry.Node do
    @moduledoc """
    A peer node in the Pastry overlay network
    
    sends reqs at 1 req/sec to either
    get/store a (K,V)

    The routing table has ceil(log_base16 N) rows with 
    16 entires each.

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
        routing_table = build_routing_table(args)

        {:ok, %{
            :id => args[:id],
            :num_reqs => args[:numRequests],
            :num_nodes => args[:numNodes],
            :map => %{},
            :total_hops => 0, # total # of hops traversed when retrieving items during lifetime
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
        {row, next_id} = route(kv[:key], state)
        cond do
            next_id == state[:id] ->
                new_map = Map.put(state[:map], kv[:key], kv[:value])
                Logger.debug "Placing key #{kv[:key]} with node #{state[:id]}"                
                {:reply, :ok, %{
                    :id => state[:id],
                    :num_reqs => state[:num_reqs],
                    :num_nodes => state[:num_nodes],
                    :map => new_map,
                    :total_hops => state[:total_hops],
                    :routing_table => state[:routing_table],
                    :leaf_set => state[:leaf_set]}}
            row == -1 ->
                Logger.warn "Failed to store key #{kv[:key]}"
                {:reply, :fail, state}
            true ->
                resp = GenServer.call({:global, next_id}, {:store, kv})
                {:reply, resp, state}            
          end  
    end

    @doc """
    Main join feature
    """
    def handle_call({:join, data}, _from, state) do  
        key = data[:key]
        path = data[:path]

        # if state[:id] is the closest node in the network
        # to the key, row_idx == shl(state[:id], key).
        # row_idxs refers to the row of the routing table
        # that needs to get updated in the joining node.
        # When the next_id comes from the leaf set and 
        # has a different prefix than the state[:id] but shared prefix with
        # the incoming node, don't use the row_idx 
        {row_idx, next_id} = route(key, state)

        if row_idx == -1 do
            Logger.warn "#{key} failed to join"
            {:reply, path, state}
        else
            shared_prefix_with_key = shl(key, state[:id], 0)
            i = min(shared_prefix_with_key, row_idx)
            msg = %{
                :id => state[:id],
                :i => i,
                :row => state[:routing_table] |> Enum.at(i)
            }

            GenServer.cast({:global, key}, {:update_routing, msg})

            if next_id == state[:id] do
                # done routing
                # send the leaf set
                GenServer.cast({:global, key}, {:init_leaf_set, state[:leaf_set]})
                {:reply, path ++ [state[:id]], state}
            else
                # pass on to the next
                new_data = %{:key => key, :path => path ++ [state[:id]]}
                reply = GenServer.call({:global, next_id}, {:join, new_data})
                {:reply, reply, state}
            end
        end
    end

    @doc """
    Go through leaf set and routing table, sending
    everyone your id
    """
    def handle_call(:update_all_after_join, _from, state) do
        Enum.map(state[:leaf_set][:smaller], fn id -> 
            GenServer.cast({:global, id}, {:announce_arrival, state[:id]}) end)
        Enum.map(state[:leaf_set][:larger], fn id -> 
            GenServer.cast({:global, id}, {:announce_arrival, state[:id]}) end)
        
        num_rows = length(state[:routing_table])
        
        Enum.map(0..num_rows-1,
            fn i -> Enum.map(0..14,
                fn j -> node = state[:routing_table] |> Enum.at(i) |> Enum.at(j)
                    if node != nil && node != state[:id] && 
                        !Heap.member?(state[:leaf_set][:smaller], node)  &&
                        !Heap.member?(state[:leaf_set][:larger], node) do
                            GenServer.cast({:global, node}, {:announce_arrival, state[:id]})
                    end
                end)
            end)

        {:reply, state, state}
    end

    @doc """
    FOR DEBUG
    """
    def handle_call(:get_state, _from, state) do
        {:reply, state, state}
    end

    def handle_cast({:found, value}, state) do
        Logger.debug "Retrieved #{value}" 
        {:noreply, state}
    end

    @doc """
    Retrieve the value at key "k"
    """
    def handle_cast({:get, data}, state) do
        key = data[:key]
        {row, next_id} = route(key, state)
        cond do
            next_id == state[:id] ->
                v = Map.get(state[:map], key)
                if v == nil do
                    Logger.debug "failed to find item with key #{key}, requested by #{data[:origin]}, search terminating at #{state[:id]}"
                end
                GenServer.cast({:global, data[:origin]}, {:found, v})
            row == -1 ->
                Logger.warn "failed to find key #{key} in the DHT"
            true ->
                GenServer.cast({:global, next_id}, {:get, data})    
        end  
        {:noreply, %{
            :id => state[:id],
            :num_reqs => state[:num_reqs],
            :num_nodes => state[:num_nodes],
            :map => state[:map],
            :total_hops => state[:total_hops] + 1,
            :routing_table => state[:routing_table],
            :leaf_set => state[:leaf_set]}}  
    end

    @doc """
    Set a row of the routing table with the incoming msg
    """
    def handle_cast({:update_routing, msg}, state) do
        # remove all entries in row that share common prefix > msg[:i] with state[:id]
        row = remove_id_from_row(msg[:row], state[:id], msg[:i])

        new_table = copy_and_update(state[:routing_table],
            msg[:i], row, msg[:id])
        {:noreply, %{
            :id => state[:id],
            :num_reqs => state[:num_reqs],
            :num_nodes => state[:num_nodes],
            :map => state[:map],
            :total_hops => state[:total_hops],
            :routing_table => new_table,
            :leaf_set => state[:leaf_set]}}   
    end

    def handle_cast({:init_leaf_set, leaf_set}, state) do
        state =  %{
            :id => state[:id],
            :num_reqs => state[:num_reqs],
            :num_nodes => state[:num_nodes],            
            :map => state[:map],
            :total_hops => state[:total_hops],
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
            new_heap = copy_and_add_heap(Heap.new(&(lt(&1, &2))), state[:leaf_set][:smaller], state[:id], id, 8)
            %{:smaller => new_heap, :larger => state[:leaf_set][:larger]}
          end

        l = shl(id, state[:id], 0)
        new_table = copy_and_update(state[:routing_table], l,
            state[:routing_table] |> Enum.at(l), id)
    
        state =  %{
            :id => state[:id],
            :num_reqs => state[:num_reqs],
            :num_nodes => state[:num_nodes],            
            :map => state[:map],
            :total_hops => state[:total_hops],
            :routing_table => new_table,
            :leaf_set => new_leaf_set}
        {:noreply, state}
    end

    def handle_info({:make_reqs, n}, state) do
        if n > 0 do
            # make a random request
            node = get_random_node(state[:id], state[:num_nodes])
            k = Enum.random(state[:num_nodes]..state[:num_nodes]*2)
            
            # initiate a get request for an item in the DHT
            GenServer.cast({:global, node},
                {:get, %{:key => Pastry.CLI.hash(Pastry.CLI.item(k)), :origin => state[:id]}})
            
            # schedule for future
            Process.send_after(self(), {:make_reqs, n - 1}, 1000)
        end
        {:noreply, state}
    end

    ##############
    # Helper Fns #
    ##############
    def get_random_node(my_id, n) do
        node = Enum.random(0..n)  
        if my_id == Pastry.CLI.hash(Integer.to_string(node)) do
            get_random_node(my_id, n)
        else
            Pastry.CLI.hash(Integer.to_string(node))
        end      
    end

    def copy_and_add_heap(new_heap, old_heap, id, new_id, i) when i > 0 and old_heap != nil do
        if new_id != "" && !Heap.member?(old_heap, new_id) do
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
            if !Heap.empty?(old_heap) do
                {root, rest} = Heap.split(old_heap)
                if !Heap.member?(new_heap, root) do 
                    Heap.push(new_heap, root) 
                        |> copy_and_add_heap(rest, id, new_id, i - 1)
                else
                    copy_and_add_heap(new_heap, rest, id, new_id, i - 1)
                end
            else
                new_heap
            end        
        end 
    end

    def copy_and_add_heap(new_heap, _old_heap, _id, _new_id, _i) do
        new_heap
    end

    def build_routing_table(args) do
        # 1 extra for the 0'th row
        num_rows = round(:math.ceil(log(args[:numNodes], 16))) * 2
        num_cols = 16  # 2^b
        Enum.map(0..num_rows,
            fn _x -> Enum.map(0..num_cols, fn _y -> nil end)
        end)         
    end

    def route(key, state) do
        # first compute dist|self - key|
        dist_self = dist(key, state[:id])
        l = shl(key, state[:id], 0)                    
        {best_lf_dist, best_lf_id} = smallest_in_leafset(key, state[:leaf_set])      
        best_lf_row_idx = shl(key, best_lf_id, 0)    
        # 3 cases for leaf set
        # 1. key falls within leaf set
        #   1a. d_self < d_leafsets -> continue to routing table
        #   1b. d_leafset* < d_self -> send to d_leafset*
        # 2. key falls outside of leaf set -> proceed to routing table
        if in_leaf_set(key, state[:leaf_set]) and best_lf_dist < dist_self and l <= best_lf_row_idx do
            # d_leafset* < d_self -> send to d_leafset*
            {best_lf_row_idx, best_lf_id}
        # check routing table
        else
            {d_l, _} = Integer.parse(String.at(key, l), 16)
            # can't route!
            r_d_l = 
              if l >= length(state[:routing_table]) do
                -1
              else
                # check if someone with id with more digits in common 
                # exists in table
                state[:routing_table] |> Enum.at(l) |> Enum.at(d_l)
              end
            
            {best_l, best_id} = 
              if r_d_l != -1 do   
                {best_l, best_id} =
                    if r_d_l != nil do
                        {l, r_d_l}
                    else
                        {best_row_dist, best_row_id} = smallest_in_row(state[:id], key, state[:routing_table] |> Enum.at(l))
                        # check if the leaf set or routing table has somethign closer
                        {l_, best} = 
                        cond do
                            best_lf_dist <= best_row_dist && best_lf_dist < dist_self && l <= best_lf_row_idx ->
                                {best_lf_row_idx, best_lf_id}
                            best_row_dist <= best_lf_dist && best_row_dist < dist_self -> 
                                {l, best_row_id}
                            # we are the closest node
                            true ->
                                {l, state[:id]}
                        end
                        {l_, best}      
                    end
                {best_l, best_id}
              else
                {-1, -1}
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
                shl(a, b, count + 1)
            else
                count
            end
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
        num_cols = 16
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

    @doc """
    Given an ID and a threshold (prefix value), 
    remove any ids from a row with geq prefix value
    """
    def remove_id_from_row(row, state_id, thresh) do
        Enum.map(row, fn row_id ->
            id = if row_id == nil do "" else row_id end 
            new_id = if shl(id, state_id, 0) > thresh do
                nil
            else
                row_id
            end
            new_id
        end)
    end


end