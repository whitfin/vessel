defmodule Wordcount.Reducer do
  @moduledoc """
  This module contains the implementation of the Wordcount reducing phase.
  """
  use Vessel.Reducer

  @doc """
  Receives key/value pairs as emitted by `Wordcount.Mapper` and emits a total.

  The logic here is simple; because the mapper outputs a word as a key against
  a 1 to represent an occurrence of a word, we just have to sum the 1s to know
  how many times a word came up.

  We use a minor optimization, because every element being 1 simply means that
  the total is the length of the values list - so we just write that out as the
  count against our word key.
  """
  def reduce(word, values, context) do
    Vessel.write(context, { word, length(values) })
  end

end
