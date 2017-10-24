defmodule NodeTest do
    @moduledoc """
    Tests functionality in the Node module 
    from the Pastry API
    """
    use ExUnit.Case
    doctest Pastry.Node

    test "initialize a Node with proper state" do
        args = %{:id => "0", :numNodes => 5, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
    end

    test "create routing table" do
        args = %{:id => "0", :numNodes => 5, :numRequests => 100}
        table = Pastry.Node.build_routing_table(args)
        assert table != nil
    end
    
    test "send a join message to with 1 node in network" do
        args = %{:id => Pastry.CLI.hash("0"), :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        # Create the new node
        args = %{:id => Pastry.CLI.hash("1"), :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        data = %{:key => Pastry.CLI.hash("1"), :path => []}
        path = GenServer.call({:global, 
            Pastry.CLI.hash("0")},
            {:join, data})

        assert path == [Pastry.CLI.hash("0")]
        # Update yourself with info from everyone on path
        Enum.map(path, fn x -> GenServer.cast({:global, Pastry.CLI.hash("1")}, {:announce_arrival, x}) end)        
        # update everyone in your new state
        GenServer.call({:global, Pastry.CLI.hash("1")}, {:update_all_after_join})

        v = "test0"
         GenServer.call({:global,
          Pastry.CLI.hash("0")},
          {:store, %{:key => Pastry.CLI.hash(v), :value => v}})

        v = "test1"
        GenServer.call({:global,
            Pastry.CLI.hash("1")},
            {:store, %{:key => Pastry.CLI.hash(v), :value => v}})
    end

    test "send a join message with > 1 node on path" do
        # Create first node
        args = %{:id => "ABCD", :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        # Create second node
        args = %{:id => "AECF", :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        data = %{:key => "AECF", :path => []}
        path = GenServer.call({:global, 
            "ABCD"},
            {:join, data})

        assert path == ["ABCD"]
        
        # verify AECF's state
        # state = GenServer.call({:global, "AECF"}, {:get_state})
        # IO.puts "Verifying AECF's state pt. 1"
        # IO.inspect(state)

        Enum.map(path, fn x -> GenServer.cast({:global, "AECF"}, {:announce_arrival, x}) end)        
        GenServer.call({:global, "AECF"}, {:update_all_after_join})

        # verify ABCD's state
        # state = GenServer.call({:global, "AECF"}, {:get_state})
        # IO.puts "Verifying AECF's state pt. 2"
        # IO.inspect(state)

        # Create third node
        args = %{:id => "AB31", :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        data = %{:key => "AB31", :path => []}
        path2 = GenServer.call({:global, 
            "AECF"},
            {:join, data})

        assert path2 == ["AECF", "ABCD"]

        Enum.map(path2, fn x -> GenServer.cast({:global, "AB31"}, {:announce_arrival, x}) end)                
        GenServer.call({:global, "AB31"}, {:update_all_after_join})
        
        k = "AB42"
        v = 1111
        GenServer.call({:global,
            "ABCD"},
            {:store, %{:key => k, :value => v}})
        
        k = "ABBF"
        v = 1221
        GenServer.call({:global,
            "AECF"},
            {:store, %{:key => k, :value => v}})
        
        k = "AF10"
        v = 5454
        GenServer.call({:global,
            "AB31"},
            {:store, %{:key => k, :value => v}})

        # state = GenServer.call({:global, "AECF"}, {:get_state})
        # IO.puts "Verifying AECF's state pt. 3"
        # IO.inspect(state)
        IO.puts "Getting!"
        
        # retrieve some spooky values
        {vv, hops} = GenServer.call({:global, "ABCD"}, {:get, %{:key => "AF10", :hops => 0}})
        IO.puts "Found #{vv} in #{hops} hops"
    end

    test "remove id from row" do
        row = [nil, nil, "ABCD", nil]
        id = "AE43"
        threshold = 0

        assert Pastry.Node.remove_id_from_row(row, id, threshold) == [nil, nil, nil, nil]

    end

end