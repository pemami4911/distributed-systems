defmodule Gossip.PushSumActor do
    @moduledoc """
    Nodes in the graph implementing the
    push-sum protocol
    """
      require Logger
      use GenServer 
    
      def start_link(args) do
        GenServer.start_link(__MODULE__, args, [{:name, {:global, args[:name]}}])
      end
    
      def init(args) do
        # args contains the name and neighbors
        state = %{:args => args, :s => args[:name], :w => 1.0, :streak => 0}
        {:ok, state}
      end
            
      def handle_cast({:init_push, _nonde}, state) do
        # transmit to random neighbor
        recipient = Enum.take_random(state[:args][:neighbors], 1)
        |> List.first
        GenServer.cast({:global, recipient}, {:push, %{:s => state[:s]/2, :w => state[:w]/2}})
        
        state = Map.replace(state, :s, state[:s]/2)
        |> Map.replace(:w, state[:w]/2)

        {:noreply, state}
      end
      @doc """
      Other actors call this method to send this Actor 
      s/2 and w/2
      """
      def handle_cast({:push, data}, state) do
        # Update s/w
        prev = state[:s] / state[:w]

        state = Map.replace(state, :s, state[:s] + data[:s])
          |> Map.replace(:w, state[:w] + data[:w])
        
        # check for convergence
        estimate = state[:s] / state[:w]
        
        state = 
          if abs(estimate - prev) < state[:args][:eps] do
            # update streak
            Map.replace(state, :streak, state[:streak] + 1)
          else
            state
          end    
        
        state =
          if state[:streak] == 3 do
            # done!
            Logger.info "#{state[:args][:name]} terminating with sum estimate #{estimate}"
            GenServer.cast({:global, :main}, {:done, true})
            state
          else 
            # transmit to random neighbor
            recipient = Enum.take_random(state[:args][:neighbors], 1)
            |> List.first
            Logger.debug "#{state[:args][:name]} is pushing to #{recipient} with sum estimate #{estimate}"
            GenServer.cast({:global, recipient}, {:push, %{:s => state[:s]/2, :w => state[:w]/2}})
            
            # update s,w
            Map.replace(state, :s, state[:s]/2)
            |> Map.replace(:w, state[:w]/2)
          end

        {:noreply, state}
      end    
    end