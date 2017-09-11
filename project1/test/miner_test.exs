defmodule MinerTest do
  use ExUnit.Case
  
  def search(gatorlink, opts, status, outs) when status != :ok do
    # construct the new string to test
    # should be valid
    full_string = gatorlink <> to_string(Enum.take_random(33..126, opts[:chars]))
    {status_, outs_} = check_hash(full_string, opts[:k])
    search(gatorlink, opts, status_, full_string <> "\t" <> outs_)     
  end

  def search(_gatorlink, _opts, _status, outs) do
    IO.puts(outs)            
  end

  def check_hash(string, k) do
    res = Base.encode16(:crypto.hash(:sha256, string))
    # count number of leading zeros
    n_zeros = count_leading_zeros(String.graphemes(res), 0)
    # if legit, return
    if n_zeros >= k do
      {:ok, res}
    else
      #IO.puts("string " <> string <> " zeros " <> to_string(n_zeros))
      {:notok, ""}
    end
  end

  def count_leading_zeros([tail | head], acc) when tail == "0" do
    acc = acc + 1
    count_leading_zeros(head, acc)
  end

  def count_leading_zeros([_tail | _head], acc) do
    acc
  end

  test "count leading zeros" do
    x = ["0", "0", "0", "4"]
    assert count_leading_zeros(x, 0) == 3
  end

  test "search, k = 3" do
    opts = [k: 1, chars: 3]
    gatorlink = "pemami"
    search(gatorlink, opts, nil, "")
  end

end
  