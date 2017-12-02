defmodule Twitter.Client.CLI do
  
  def main(args) do 
    {opts, _, _} = OptionParser.parse(args, switches: [config: :string])
    opts_ = opts ++ [main: self()]

    experiment = Twitter.Sim.init(opts_) |> String.trim
    # run for 60 seconds
    Process.send_after(self(), {:done, []}, 60*1000)
    receive do
      {:done, _msg} ->
        res = GenServer.call({:global, Twitter.Engine}, :tweet_count)
        log_result(["#{experiment},#{res / 60}\n"])
        System.halt(0)
    end
  end

  defp log_result(result) do
    {:ok, file} = File.open("results.log", [:append])
    save_results(file, result)
    File.close(file)
  end

  defp save_results(file, []), do: :ok
  defp save_results(file, [data|rest]) do
      IO.binwrite(file, data)
      save_results(file, rest)
  end

end