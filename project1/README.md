# Bitcoin

The goal of this project is to create a distributed Bitcoin mining system. A boss creates tasks for workers to search for Bitcoins. 
The input is the number of leading 0's in the SHA256 hash for the bitcoin. The following string is hardcoded 
as the target: pemami$;234kxlq

The output are the Bitcoins with the corresponding number (or less) of leading 0's. 

## Leaderboard

| # of leading zeros | String | Hash | 
| --- | --- | --- |
| 8 | pemami'A;rl)N7 | 000000001E450E87A534729604E28AEE0E855BFC8D08557FBDF72174A88E8D06 | 
| 7 | pemami(<Ttyuf | 0000000C6A2DBB3FE5193B6455EFCE8CD44765729AB286E417B95048A6AB828E |

#### Timing

real: 39m32.269s
user: 152m58.596s
sys: 0m43.400s
utilization: 0.2577

## Implementation 

This can be done with a Supervisor and Tasks. 
 
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `project1` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:project1, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/project1](https://hexdocs.pm/project1).

