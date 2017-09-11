defmodule Bitcoin.Miner do  
  use Task

  def start_link(opts) do
    Task.start_link(__MODULE__, :search, [opts])
  end
  
  @doc """
    Recursive function that tries hashing different strings.
    Once a Bitcoin is found, outputs to the terminal the result
    and exits.
  """
  def search(opts) do
    search("pemami", opts, nil, "")  
  end

  def search(gatorlink, opts, status, _outs) when status != :ok do
    # construct the new string to test
    # should be valid
    full_string = gatorlink <> to_string(Enum.take_random(33..126, opts[:chars]))
    {status_, outs_} = check_hash(full_string, opts[:k])
    search(gatorlink, opts, status_, full_string <> "\t" <> outs_)     
  end

  def search(_gatorlink, _opts, _status, outs) do
    IO.puts(outs)            
  end

  defp check_hash(string, k) do
    res = Base.encode16(:crypto.hash(:sha256, string))
    # count number of leading zeros
    n_zeros = count_leading_zeros(String.graphemes(res), 0)
    # if legit, return
    if n_zeros >= k do
      {:ok, res}
    else
      {:notok, ""}
    end
  end

  defp count_leading_zeros([tail | head], acc) when tail == "0" do
    acc = acc + 1
    count_leading_zeros(head, acc)
  end

  defp count_leading_zeros([_tail | _head], acc) do
    acc
  end

end