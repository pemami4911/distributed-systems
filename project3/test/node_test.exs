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
        new_map = GenServer.call({:global,
          Pastry.CLI.hash("0")},
          {:store, %{:key => Pastry.CLI.hash(v), :value => v}})

        assert new_map == %{Pastry.CLI.hash(v) => v}

        v = "test1"
        GenServer.call({:global,
            Pastry.CLI.hash("1")},
            {:store, %{:key => Pastry.CLI.hash(v), :value => v}})
    end

    test "send a join message with > 1 node on path" do
        args = %{:id => "ABCD", :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        # Create first node
        args = %{:id => "AECF", :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        data = %{:key => "AECF", :path => []}
        path = GenServer.call({:global, 
            "ABCD"},
            {:join, data})

        assert path == ["ABCD"]
        
        Enum.map(path, fn x -> GenServer.cast({:global, "AECF"}, {:announce_arrival, x}) end)        
        GenServer.call({:global, "AECF"}, {:update_all_after_join})

        #assert state == 0

        # Create second node
        args = %{:id => "ABCF", :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        data = %{:key => "ABCF", :path => []}
        path2 = GenServer.call({:global, 
            "AECF"},
            {:join, data})

        assert path2 == ["AECF", "ABCD"]

        Enum.map(path, fn x -> GenServer.cast({:global, "ABCF"}, {:announce_arrival, x}) end)                
        GenServer.call({:global, "ABCF"}, {:update_all_after_join})
        
        # v = "test0"
        # GenServer.call({:global,
        #     "ABCD"},
        #     {:store, %{:key => Pastry.CLI.hash(v), :value => v}})
        # v = "test1"
        # GenServer.call({:global,
        #     "AECF"},
        #     {:store, %{:key => Pastry.CLI.hash(v), :value => v}})
        
        # v = "test2"
        # GenServer.call({:global,
        #     "ABCF"},
        #     {:store, %{:key => Pastry.CLI.hash(v), :value => v}})
    
    end

end