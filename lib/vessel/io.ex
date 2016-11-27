defmodule Vessel.IO do
  @moduledoc """
  This module contians a collection of utility functions designed to deal with
  Job IO, whether it be incoming or outgoing IO.

  Currently only functions to write to the Context streams are exposed, along
  with utility functions for splitting inputs when sorting.

  This module will likely grow in future, but an end-user should basically never
  have to call anything in this module directly - it's purely for internal use
  (and as such, be aware that any function may be removed/modified at any time).
  """

  @doc """
  Splits a binary pair into a two-element Tuple.

  A binary pair is a line of input, with a tab character separating the key and
  value. We trim the trailing newline, and split on the first (and only first)
  tab character, before returning the generated List.
  """
  @spec split(binary, binary, integer) :: { binary, binary }
  def split(val, sep, cnt)
    when is_binary(val) and is_binary(sep) and is_integer(cnt)
  do
    { key_parts, val_parts } =
      val
      |> String.trim_trailing("\n")
      |> String.split(sep)
      |> Enum.split(cnt)

    {
      Enum.join(key_parts, sep),
      Enum.join(val_parts, sep)
    }
  end

  @doc """
  Writes a message out to a contextual error stream.

  We write using the IO protocol to the process defined in the `:stderr` key of
  the Vessel context.
  """
  @spec stderr(Vessel.t, binary) :: :ok
  def stderr(%{ stderr: stderr }, msg) when is_binary(msg),
    do: IO.write(stderr, msg)

  @doc """
  Writes a message out to a contextual output stream.

  We write using the IO protocol to the process defined in the `:stdout` key of
  the Vessel context.
  """
  @spec stdout(Vessel.t, binary) :: :ok
  def stdout(%{ stdout: stdout }, msg) when is_binary(msg),
    do: IO.write(stdout, msg)

end
