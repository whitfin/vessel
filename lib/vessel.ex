defmodule Vessel do
  @moduledoc """
  The main interface for interacting with Vessel from withing application code.

  This module contains many utilities related to interacting with the Vessel Job
  context, as well as convenience functions for logging, and writing values to
  the next Job steps.

  Any function in this module should require the Job context as the first param,
  in order to future proof in case of new configuration options being added.
  """

  # add aliases
  alias Vessel.Conf

  # add our opaque type for specs
  @opaque t :: %__MODULE__{ }

  # context
  defstruct [
    # Job user related items
    args: [], private: %{},
    # Job execution metadata
    conf: Conf.new(), count: 0, group: nil,
    # IO related fun stuff
    stderr: :stderr, stdout: :stdio
  ]

  @doc """
  Retrieves a value from the Job configuration.

  Configuration values are treated as environment variables to conform to Hadoop
  Streaming. We clone the environment into the context (to avoid setting the env
  values rather than the job variables).

  We only allow lower case variables to enter the Job configuration, as this is
  the model used by Hadoop Streaming. This also filters out a lot of noise from
  default shell variables polluting the configuration (e.g. $HOME etc).

  Using environment variables means that there's a slight chance that you'll
  receive a value from the env which isn't actually a configuration variable, so
  please validate appropriately.
  """
  @spec get_conf_variable(Vessel.t, any, any) :: any
  def get_conf_variable(%{ conf: conf }, key, default \\ nil),
    do: Map.get(conf, key, default)

  @doc """
  Retrieves a private key and value from the context.

  An optional default value can be provided to be returned if the key does not
  exist in the private context. If not provided, `nil` will be used.
  """
  @spec get_private(Vessel.t, any, any) :: any
  def get_private(%{ private: private }, field, default \\ nil),
    do: Map.get(private, field, default)

  @doc """
  Inspects a value and outputs to the Hadoop logs.

  You can pass your value as either the first or second argument, as long as the
  other one is a Vessel context - this is to make it easier to chain, in the same
  way you would with `IO.inspect/2`.

  This function uses `:stderr` as Hadoop is listening to all `:stdio` output as
  the results of your mapper - so going via `:stdio` would corrupt the Job values.
  """
  @spec inspect(Vessel.t | any, Vessel.t | any, Keyword.t) :: any
  def inspect(value, ctx, opts \\ [])
  def inspect(%{ stderr: stderr }, value, opts),
    do: IO.inspect(stderr, value, opts)
  def inspect(value, %{ stderr: _stderr } = ctx, opts),
    do: inspect(ctx, value, opts)

  @doc """
  Outputs a message to the Hadoop logs.

  This function uses `:stderr` as Hadoop is listening to all `:stdio` output as
  the results of your mapper - so going via `:stdio` would corrupt the Job values.
  """
  @spec log(Vessel.t, binary | any) :: :ok
  def log(ctx, msg) when is_binary(msg),
    do: stderr(ctx, "#{msg}\n")
  def log(ctx, msg),
    do: log(ctx, inspect(msg))

  @doc """
  Stores a private key and value inside the context.

  This is where you can persist values between steps in the Job. You can think
  of it as the Job state. You should only change things in this Map, rather than
  placing things in the top level of the Job context.
  """
  @spec put_private(Vessel.t, any, any) :: Vessel.t
  def put_private(%{ private: private } = ctx, field, value),
    do: %{ ctx | private: Map.put(private, field, value) }

  @doc """
  Sets a variable in the Job configuration.

  This operates in a similar way to `put_private/3` except that it should only
  be used for Job configuration values (as a semantic difference).

  This does not set the variable in the environment, as we clone the environment
  Job configuration on startup to avoid polluting the environment.
  """
  @spec set_conf_variable(Vessel.t, any, any) :: Vessel.t
  def set_conf_variable(%{ conf: conf } = ctx, field, value),
    do: %{ ctx | conf: Map.put(conf, field, value) }

  @doc """
  Updates a Hadoop Job counter.

  This is a utility function to emit a Job counter in Hadoop Streaming. You may
  provide a custom amount to increment by, which defaults to `1` if not provided.
  """
  @spec update_counter(Vessel.t, binary, binary, number) :: :ok
  def update_counter(ctx, group, counter, amount \\ 1),
    do: stderr(ctx, "reporter:counter:#{group},#{counter},#{amount}\n")

  @doc """
  Updates the status of the Hadoop Job.

  This is a utility function to emit status in Hadoop Streaming.
  """
  @spec update_status(Vessel.t, binary) :: :ok
  def update_status(ctx, status),
    do: stderr(ctx, "reporter:status:#{status}\n")

  @doc """
  Writes a key/value Tuple to the Job context.

  To stay compatible with Hadoop Streaming, this will emit to `:stdio` in the
  required format.
  """
  @spec write(Vessel.t, { any, any }) :: :ok
  def write(ctx, { key, value }),
    do: write(ctx, key, value)

  @doc """
  Writes a value to the Job context for a given key.

  To stay compatible with Hadoop Streaming, this will emit to `:stdio` in the
  required format.
  """
  @spec write(Vessel.t, any, any) :: :ok
  def write(ctx, key, value),
    do: stdout(ctx, "#{key}\t#{value}\n")

  # Writes out a message to `:stdio` using the contextual `:stdout`
  defp stderr(%{ stderr: stderr }, msg), do: IO.write(stderr, msg)

  # Writes out a message to `:stderr` using the contextual `:stderr`
  defp stdout(%{ stdout: stdout }, msg), do: IO.write(stdout, msg)

end
