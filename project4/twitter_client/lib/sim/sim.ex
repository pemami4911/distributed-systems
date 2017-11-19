defmodule Twitter.Sim do
@moduledoc """
Various helper fns for running Twitter simulations
"""
  use Supervisor

  def start_link(opts) do

  end

  def init(opts) do

  end

  @doc """
  Return a map, populated by the provided config file
  """
  defp parse_config(fname) do
    File.read!(fname) 
      |> String.split("\n")
      |> Enum.reduce(%{}, fn item, map -> 
        s = String.split(item, "=")
        Map.put(map, List.first(s), List.last(s))
        end)
  end

  @doc """
  Configure a Twitter user
  """
  defp init_user(opts) do
  end

  @doc """
  Generates usernames
  """
  defp make_usernames(n) do
    Enum.reduce([], fn i -)
  
  end

  @doc """
  Allocate followers according to Zipf distribution
  """
  defp followers() do
  end

  
end