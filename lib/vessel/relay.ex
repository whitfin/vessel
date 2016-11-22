defmodule Vessel.Relay do
  @moduledoc """
  This module acts as a relay IO stream to allow redirection of pairs written by
  Vessel. This is mainly provided for in-application MapReduce and for testing.

  The concept behind this module is quite simply a buffer of the messages which
  have been received from the IO stream. There are a few utility functions which
  allow you to act on the buffer, or flush it entirely.

  An example usage of this module is to start the Relay and pass the process id
  through to the `stdout/stderr` options inside the `consume/1` callback of a
  Vessel mapper or reducer. The output messages will then be received by Relay
  and can be easily used to test your components from inside unit tests.
  """
  use GenServer

  # add alias, IO is taken
  alias Vessel.IO, as: Vio

  # define process type
  @type server :: GenServer.server

  @doc """
  Flushes the Relay buffer.

  This simply throws away the current buffer stored in the Relay. No other actions
  will remove from the currently stored buffer, nor is there a way to modify the
  stored buffer.
  """
  @spec flush(server) :: :ok
  def flush(pid),
    do: GenServer.call(pid, { :relay, :flush })

  @doc """
  Forwards the entire Relay buffer to a process.

  This is to aid in testing so you may simple use receive assertions. This will
  simply send a Tuple message per buffer element (in order of reception) of the
  form `{ :relay, msg }`.
  """
  @spec forward(server, server) :: :ok
  def forward(pid, ref),
    do: pid |> get |> Enum.each(&send(ref, { :relay, &1 }))

  @doc """
  Retrieves the ordered Relay buffer.

  This pulls back the raw buffer from the Relay and reverses it, to ensure that
  messages are correctly ordered.
  """
  @spec get(server) :: [ binary ]
  def get(pid),
    do: pid |> raw |> Enum.reverse

  @doc """
  Retrieves the raw Relay buffer.

  This is return in a reversed order, if you want the correctly ordered buffer,
  please use `Vessel.Relay.get/1`.
  """
  @spec raw(server) :: [ binary ]
  def raw(pid),
    do: GenServer.call(pid, { :relay, :raw })

  @doc """
  Retrieves a sorted Relay buffer.

  This sort here is sorted in the same was as the values sorted after Hadoop has
  received them. You should not have to sort after the reducing phase, only after
  the mapping phase.
  """
  @spec sort(server) :: [ binary ]
  def sort(pid),
    do: pid |> raw |> Vio.sort

  @doc """
  Streams a sorted Relay buffer.

  There is no memory advantage to streaming here, but the `Vessel.Pipe` module
  expects stream input - so converting the buffer to a Stream means that we can
  easily pipe through values internally between stages.
  """
  @spec stream(server) :: Stream.t
  def stream(pid) do
    Stream.resource(
      fn -> sort(pid) end,
      fn
        ([ ]) ->
          { :halt, [] }
        ([ head | tail ]) ->
          { [head], tail }
      end,
      fn(_) -> nil end
    )
  end

  @doc false
  # Responds to a call to flush the existing buffer. We do this just by ignoring
  # the existing state and simply setting an empty list as the new buffer.
  def handle_call({ :relay, :flush }, _ctx, _buffer),
    do: { :reply, :ok, [] }

  @doc false
  # Retrieves the raw buffer from the server, without doing any modification. We
  # don't even sort the output in case it's a large buffer which could potentially
  # block the server process to other messages coming in.
  def handle_call({ :relay, :raw }, _ctx, buffer),
    do: { :reply, buffer, buffer }

  @doc false
  # Handles a number of IO requests per the IO protocol. The IO protocol dictates
  # that we response using the last element in the request list, but we don't as
  # we want best performance and we ack before we even bother to persist (as we
  # can guarantee that the requests never fail).
  def handle_info({ :requests, requests }, buffer) do
    # pull the caller and reference from the first message in the lists
    [ { :io_request, caller, ref, _msg } | _rest ] = requests
    # acknowledge the IO call, per the protocol
    ack(caller, ref)
    # reduce the request list into a new buffer of messages
    { :noreply, Enum.reduce(requests, buffer, &prep_buffer/2) }
  end

  @doc false
  # Receives a single IO request, and simply acknowledges it per the IO protocol
  # before prepending it to the existing buffer stored in the state.
  def handle_info({ :io_request, caller, ref, _msg } = req, buffer) do
    # acknowledge the IO call, per the protocol
    ack(caller, ref)
    # add the new message to the state and return the buffer
    { :noreply, prep_buffer(req, buffer) }
  end

  # This is just sugar for the IO acknowledgement, to avoid typos. This will just
  # return :ok to the caller with the provided reference to make sure that we don't
  # hang the calling IO process (which will usually be a MapReduce job).
  defp ack(caller, ref),
    do: send(caller, { :io_reply, ref, :ok })

  # Just prepends a received message to the provided buffer. This is trivial but
  # is factored out just because we use this behaviour in multiple places and it
  # makes the matching more convenient to do it in the function head.
  defp prep_buffer({ :io_request, _c, _r, { _p, _e, msg } }, buf),
    do: [ msg | buf ]

end
