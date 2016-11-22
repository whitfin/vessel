defmodule Vessel.Pipe do
  @moduledoc false
  # This module contains the base Stream pipe for a MapReduce job.
  #
  # Each pipe contains a lifecycle which can be attached to by modules which `use`
  # a Pipe. The `setup/1`, `handle_line/2` and `cleanup/1` callbacks can be
  # overridden in order to control what executes at each state in the pipeline.
  #
  # A Pipe can either be used manually, or via an escript. Escripts are used for
  # executable usage, typically when used with Hadoop Streaming. They are required
  # to use `:stdio` as the input Stream for this reason.
  #
  # If you provide a manual Stream, you can access `consume/2` directly (but you
  # likely should not do so). This is how you can use Vessel for pure within-app
  # MapReduce style processing, without a Hadoop dependency.

  @doc false
  defmacro __using__(_) do
    quote location: :keep do

      @doc false
      def main(args) do
        :stdio
        |> IO.stream(:line)
        |> consume([ args: args ])
      end

      @doc false
      def consume(stream, options \\ []) do
        ctx = Vessel.context([
          args:   Keyword.get(options,   :args,      []),
          stdout: Keyword.get(options, :stdout,  :stdio),
          stderr: Keyword.get(options, :stderr, :stderr)
        ])

        ctx = handle_create(ctx)

        stream
        |> Enum.reduce(ctx, &handle_process/2)
        |> handle_destroy
      end

      @doc false
      def setup(ctx) do
        ctx
      end

      @doc false
      def handle_start(ctx) do
        ctx
        |> setup
        |> handle_return(ctx)
      end

      @doc false
      def handle_line(_line, ctx) do
        ctx
      end

      @doc false
      def handle_end(ctx) do
        ctx
        |> cleanup
        |> handle_return(ctx)
      end

      @doc false
      def cleanup(ctx) do
        ctx
      end

      # Handles the start state, by allowing the implementing module to override
      # the `handle_start/1` and `setup/1` events without having to worry about
      # what they're returning. If they return a context, it's passed on, but if
      # not then we just pass through the existing context.
      defp handle_create(ctx) do
        ctx
        |> handle_start
        |> handle_return(ctx)
      end

      # Handles the processing state, by allowing the implementing module to
      # override the `handle_line/2` event without having to worry about what
      # they're returning. If they return a context, it's passed on, but if
      # not then we just pass through the existing context.
      defp handle_process(line, ctx) do
        line
        |> handle_line(ctx)
        |> handle_return(ctx)
      end

      # Handles the start state, by allowing the implementing module to override
      # the `handle_end/1` and `cleanup/1` events without having to worry about
      # what they're returning. If they return a context, it's passed on, but if
      # not then we just pass through the existing context.
      defp handle_destroy(ctx) do
        ctx
        |> handle_end
        |> handle_return(ctx)
      end

      # Detects if the pass through value is a Vessel context, and returns it if
      # it is. If it is not, we return the second argument to ensure that a valid
      # context is passed through to the next step.
      defp handle_return(%Vessel{ } = ctx, _ctx),
        do: ctx
      defp handle_return(_result, %Vessel{ } = ctx),
        do: ctx

      # allow overriding all definitions
      defoverridable [
        # user overrides
        setup: 1, cleanup: 1,
        # pipe overrides in implementation modules
        handle_start: 1, handle_line: 2, handle_end: 1
      ]
    end
  end

end
