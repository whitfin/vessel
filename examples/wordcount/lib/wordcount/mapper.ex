defmodule Wordcount.Mapper do
  @moduledoc """
  This module contains the implementation of the Wordcount mapping phase.
  """
  use Vessel.Mapper

  @doc """
  Defines the mapping functions to receive input lines and map into words.

  The first definition simply ignores empty lines, as we would otherwise count
  blank words. We do nothing but return the context.

  The second definition receives a line of input, and trims the ends before then
  replacing punctuation and multiple spaces to avoid invalid words being found.
  We then just split on a single space before iterating through the words we're
  left with and writing them out with a value of 1.
  """
  def map(_key, "", context),
    do: context
  def map(_key, value, context) do
    words =
      value
      |> String.trim
      |> String.replace(~r/\p{P}(\s|$)/, "\\g{1}")
      |> String.replace(~r/\s{2,}/, " ")
      |> String.split(" ")

    Enum.each(words, fn(word) ->
      Vessel.write(context, { word, 1 })
    end)
  end

end
