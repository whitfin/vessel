defmodule Vessel.Conf do
  @moduledoc """
  This module contains utility functions for defining a configuration.

  This exists purely to keep the logic our of the main `Vessel` module to avoid
  code bloat, and to aid in making the environment configuration easier to test
  against.
  """

  # Regex to ensure no upper case
  @non_upper ~r/^[^A-Z\.]+$/

  @doc """
  Creates a new Job configuration from a Map.

  This is typically called with `System.get_env/1` as this is the behaviour used
  with the Hadoop Streaming framework. We remove all keys with capitals, as the
  Hadoop Streaming spec states that all values are lower cased.
  """
  @spec new(map) :: map
  def new(env \\ System.get_env()) when is_map(env) do
    env
    |> Enum.filter(&filter_env/1)
    |> Enum.into(%{})
  end

  # Just a local function to deal with the key/value filtering from the context
  # environment within Hadoop Streaming. This just is a Regex match.
  defp filter_env({ key, _value }) do
    !Regex.match?(@non_upper, key)
  end

end
