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
        
        v = "test0"
        new_map = GenServer.call({:global,
          Pastry.CLI.hash("0")},
          {:store, %{:key => Pastry.CLI.hash(v), :value => v}})

        assert new_map == %{Pastry.CLI.hash(v) => v}

        # Create the new node
        args = %{:id => Pastry.CLI.hash("1"), :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        v = "test1"
        GenServer.call({:global,
            Pastry.CLI.hash("1")},
            {:store, %{:key => Pastry.CLI.hash(v), :value => v}})

        assert GenServer.call({:global, 
            Pastry.CLI.hash("0")},
            {:join, Pastry.CLI.hash("1")}) == :ok
    end

    test "send a join message with > 1 node on path" do
        args = %{:id => "ABCD", :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        v = "test0"
        GenServer.call({:global,
          "ABCD"},
          {:store, %{:key => Pastry.CLI.hash(v), :value => v}})

        # Create first node
        args = %{:id => "AECF", :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        v = "test1"
        GenServer.call({:global,
            "AECF"},
            {:store, %{:key => Pastry.CLI.hash(v), :value => v}})

        assert GenServer.call({:global, 
            "ABCD"},
            {:join, "AECF"}) == :ok

        # Create second node
        args = %{:id => "ABCF", :numNodes => 100, :numRequests => 100}
        {:ok, _} = Pastry.Node.start_link(args)
        
        v = "test2"
        GenServer.call({:global,
            "ABCF"},
            {:store, %{:key => Pastry.CLI.hash(v), :value => v}})

        assert GenServer.call({:global, 
            "AECF"},
            {:join, "ABCF"}) == :ok
    end

end