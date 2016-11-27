defmodule Vessel.Mapper do
  @moduledoc """
  This module contains the implementation of the Mapper behaviour for Vessel.

  A Mapper uses a Vessel Pipe in order to receive input split by lines and pass
  them through to the mapping function. The key for the Mapper is just a binary
  representation of the nth record - i.e. the first record will be "1", the next
  "2", etc. They're binary in order to conform to typical Hadoop standards, and
  it also provides us an easy migration in case we need to move away from numbers
  in future.

  You can store state by using `Vessel.put_private/3` and returning the Vessel
  context at any point in the lifecycle. You can use `Vessel.get_private/3` or
  matching in order to retrieve values - but do not modify any other root fields
  inside the Vessel context as this is where job state is tracked. If you do not
  return a Vessel context, it will ignore the return value and remain unchanged.

  Values written from inside the Mapper will be converted to binary output which
  means that you will have to re-parse them from inside the Reducer. This is due
  to Hadoop Streaming passing everything via stdio and so there's no way to keep
  the typing consistent at this time.
  """

  @doc """
  Invoked prior to any values being read from the stream.

  This allows for setup and initialization within your Mapper. This is where you
  should start any dependencies, or construct any variables. If you need to store
  your variables for later, you should make use of `Vessel.put_private/3` and
  make sure that you return the modified context.

  If you don't return a valid context, the mapping phase will execute with the
  default context (so always ensure you're explicitly returning it just to be
  safe).
  """
  @callback setup(ctx :: Vessel.t) :: Vessel.t | any

  @doc """
  Invoked once for every input segment (usually a line of text).

  The first argument is the key, and the second value is your text input. The
  type of both will be a binary, with the key being a binary counter.

  The final argument is the Vessel context. This is passed through when calling
  functions like `Vessel.write/3` in order to write values to the Job context.
  This context is purely an application-level construct for Vessel to work with,
  it does not represent the Hadoop Job Context (as there's no way to do so in
  Hadoop Streaming).

  If you wish to write any values, you must do so calling `Vessel.write/3`, which
  writes your value to the intermediate stream. You can write as many as you
  wish within one call to `map/3`, in case your logic needs to generate multiple
  records.

  The return value of this function is ignored unless it is a Vessel context
  which has been modified using `Vessel.put_private/3`, in which case it is kept
  to be used as the context going forward.
  """
  @callback map(key :: binary, value :: binary, ctx :: Vessel.t) :: Vessel.t | any

  @doc """
  Invoked after all values have been read from the stream.

  Basically the counterpart to the `setup/` callback, in order to allow you to
  clean up any temporary files you may have written, or close any connections,
  etc.

  The returned context here will be the final context, but it's highly unlikely
  you'll need to modify the context at this point.
  """
  @callback cleanup(ctx :: Vessel.t) :: Vessel.t | any

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      # inherit piping
      use Vessel.Pipe

      # inherit Mapper behaviour
      @behaviour Vessel.Mapper

      @doc false
      def map(key, value, ctx) do
        Vessel.write(ctx, { key, value })
      end

      @doc false
      def handle_start(ctx) do
        input  = Vessel.get_conf(ctx, "stream.map.input.field.separator",  "\t")
        output = Vessel.get_conf(ctx, "stream.map.output.field.separator", "\t")

        ctx
        |> Vessel.put_meta(:separators, { input, output })
        |> super
      end

      @doc false
      def handle_line(line, %{ meta: %{ count: count } } = ctx) do
        trimmed = String.trim_trailing(line, "\n")

        new_ctx =
          count
          |> to_string
          |> map(trimmed, ctx)
          |> handle_return(ctx)

        super(line, new_ctx)
      end

      @doc false
      def handle_end(ctx) do
        super(ctx)
      end

      # We allow overriding map (obviously)
      defoverridable [ map: 3 ]
    end
  end

end
