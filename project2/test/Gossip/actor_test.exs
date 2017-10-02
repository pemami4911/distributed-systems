defmodule ActorTest do
  use ExUnit.Case
  doctest Gossip.Actor

  defp check_actors(actor1, actor2, actor3, lim) do
    recv_count1 = GenServer.call(actor1, :check_recv)
    recv_count2 = GenServer.call(actor2, :check_recv)
    recv_count3 = GenServer.call(actor3, :check_recv)
    
    if recv_count1 < lim || recv_count2 < lim || recv_count3 < lim do
      check_actors(actor1, actor2, actor3, lim)
    end
  end

  test "start an actor, give it a rumor to send and test it broadcasts it" do
    args1 = [{:name, :Actor1}, {:neighbors, [:Actor2, :Actor3]},
      {:gossip_limit, 10}]
    args2 = [{:name, :Actor2}, {:neighbors, [:Actor1, :Actor3]},
      {:gossip_limit, 10}]
    args3 = [{:name, :Actor3}, {:neighbors, [:Actor1, :Actor2]},
      {:gossip_limit, 10}]

    {:ok, actor1} = Gossip.Actor.start_link(args1)
    {:ok, actor2} = Gossip.Actor.start_link(args2)
    {:ok, actor3} = Gossip.Actor.start_link(args3)

    GenServer.cast(actor1, {:rumor, "test"})

    # Wait until all have received 10 messages
    check_actors(actor1, actor2, actor3, 10)
  end

end