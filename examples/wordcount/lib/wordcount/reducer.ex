defmodule Wordcount.Reducer do
  @moduledoc """
  This module contains the implementation of the Wordcount reducing phase.
  """
  use Vessel.Reducer

  @doc """
  Receives key/value pairs as emitted by `Wordcount.Mapper` and emits a total.

  The logic here is simple; because the mapper outputs a word as a key against
  a 1 to represent an occurrence of a word, we just have to sum the values to know
  how many times a word came up.

  This reducer is written in such a way that it can also be used as a combiner
  to lower the amount of IO/memory overhead between phases. This is especially
  important when dealing with large input as Erlang is eager with `:stdin`.

  If you were to use this reducer without a combiner, you could simply write out
  `length(values)` as the total count due to each value always being 1. With a
  combiner we cannot make this assumption, and so we have to sum to be safe.
  """
  def reduce(word, values, context),
    do: Vessel.write(context, { word, parse_sum(values) })

  # Calculates the total number of occurrences for the current word, by iterating
  # the list of values, parsing them into integers, and summing them.
  defp parse_sum(values) do
    values
    |> Enum.map(&String.to_integer/1)
    |> Enum.sum
  end

end
