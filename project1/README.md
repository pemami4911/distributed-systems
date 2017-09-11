# Bitcoin

The goal of this project is to create a distributed Bitcoin mining system. A boss creates tasks for workers to search for Bitcoins. 
The input is the number of leading 0's in the SHA256 hash for the bitcoin. The following string is hardcoded 
as the target: pemami$;234kxlq

The output are the Bitcoins with the corresponding number (or less) of leading 0's. 

## Implementation 

This can be done with a Supervisor and GenServer. A server should be able to do the mining without any workers, but should be able to accomodate workers when available. 
 
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

