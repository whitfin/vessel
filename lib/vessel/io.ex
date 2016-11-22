defmodule Vessel.IO do
  @moduledoc """
  This module contians a collection of utility functions designed to deal with
  Job IO, whether it be incoming or outgoing IO.

  Currently only functions to write to the Context streams are exposed, along
  with utility functions for sorting Mapper output, and splitting Reducer input.

  This module will likely grow in future, but an end-user should basically never
  have to call anything in this module directly - it's purely for internal use
  (and as such, be aware that any function may be removed/modified at any time).
  """

  @doc """
  Sorts the output of a mapping phase per Hadoop's ordering.

  This sort will order the messages by key, using natural ordering, descending.
  This is how Hadoop sorts pairs after the mapping phase, and so provides a mock
  replication of the actual environment.
  """
  @spec sort([ binary ]) :: [ binary ]
  def sort(output) when is_list(output),
    do: Enum.sort(output, &do_sort/2)

  @doc """
  Splits a binary pair into a two-element List.

  A binary pair is a line of input, with a tab character separating the key and
  value. We trim the trailing newline, and split on the first (and only first)
  tab character, before returning the generated List.
  """
  @spec split(binary) :: [ binary, ... ]
  def split(value) when is_binary(value) do
    value
    |> String.trim_trailing("\n")
    |> String.split("\t", [ parts: 2 ])
  end

  @doc """
  Writes a message out to a contextual stderr.

  We write using the IO protocol to the process defined in the `:stderr` key of
  the Vessel context.
  """
  @spec stderr(Vessel.t, binary) :: :ok
  def stderr(%{ stderr: stderr }, msg) when is_binary(msg),
    do: IO.write(stderr, msg)

  @doc """
  Writes a message out to a contextual stdout.

  We write using the IO protocol to the process defined in the `:stdout` key of
  the Vessel context.
  """
  @spec stdout(Vessel.t, binary) :: :ok
  def stdout(%{ stdout: stdout }, msg) when is_binary(msg),
    do: IO.write(stdout, msg)

  # Sorts two values by splitting them and comparing the keys based on natural
  # ordering, per the standard Hadoop sorting method.
  defp do_sort(left, right) do
    [ lkey, _lval ] = split(left)
    [ rkey, _rval ] = split(right)
      rkey > lkey
  end

end
