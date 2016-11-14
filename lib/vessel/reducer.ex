defmodule Vessel.Reducer do
  @moduledoc """
  This module contains the implementation of the Reducer behaviour for Vessel.

  We implement a Pipe and simply group keys to their values on the fly and pass
  them through in batches to the `reduce/3` implementation. We keep the order of
  values received just to make sure we're consistent with the Hadoop Streaming
  interface (so we don't have to document any differences).

  You can store state by using `Vessel.put_private/3` and returning the Vessel
  context at any point in the lifecycle. You can use `Vessel.get_private/3` or
  matching in order to retrieve values - but do not modify any other root fields
  inside the Vessel context as this is where job state is tracked. If you do not
  return a Vessel context, it will ignore the return value and remain unchanged.
  """

  @doc """
  Invoked prior to any values being read from the stream.

  This allows for setup and initialization within your Reducer. This is where you
  should start any dependencies, or construct any variables. If you need to store
  your variables for later, you should make use of `Vessel.put_private/3` and
  make sure that you return the modified context.

  If you don't return a valid context, the reducer phase will execute with the
  default context (so always ensure you're explicitly returning it just to be
  safe).
  """
  @callback setup(ctx :: Vessel.t) :: Vessel.t | any

  @doc """
  Invoked once for every set of values against a key.

  The first argument is the key, and the second value is a list of values. Both
  types here will be Strings due to the nature of Hadoop Streaming, which means
  you may have to parse these values appropriately. If you write a 5 from your
  Mapper, it will be received as a "5" in your Reducer and need to be converted.
  This is due to Hadoop Streaming passing everything via stdio. It may be that
  this changes in a future version of Vessel, if possible.

  The final argument is the Vessel context. This is passed through when calling
  functions like `Vessel.write/3` in order to write values to the Job context.
  This context is purely an application-level construct for Vessel to work with,
  it does not represent the Hadoop Job Context (as there's no way to do so in
  Hadoop Streaming).

  If you wish to write any values, you must do so by calling `Vessel.write/3`,
  which writes your value to the intermediate stream. You can write as many as
  you wish within one call to `reduce/3`, in case your logic needs to generate
  many records.

  The return value of this function is ignored unless it is a Vessel context
  which has been modified using `Vessel.put_private/3`, in which case it is kept
  to be used as the context going forward.
  """
  @callback reduce(key :: binary, value :: [ binary ], ctx :: Vessel.t) :: any

  @doc """
  Invoked after all values have been read from the stream.

  Basically the counterpart to the `setup/1` callback, in order to allow you to
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

      # add alias
      alias Vessel.Term

      # inherit Reducer behaviour
      @behaviour Vessel.Reducer

      @doc false
      def reduce(key, value, ctx) do
        Vessel.write(ctx, { key, value })
      end

      @doc false
      def handle_start(%Vessel{ } = ctx) do
        super(ctx)
      end

      @doc false
      def handle_line(line, ctx) do
        new_ctx =
          line
          |> convert_line
          |> handle_convert(ctx)

        super(line, new_ctx)
      end

      @doc false
      def handle_end(%Vessel{ } = ctx) do
        ctx
        |> reduce_detect
        |> Map.put(:group, nil)
        |> super
      end

      # Converts an line coming through stdin to the correct form for MapReduce,
      # by trimming the trailing newline and splitting into two parts. The spec
      # states that anything up to the first tab character is the key, and what
      # follows is the value. The output of this function is just a two-element
      # List; we could turn it into a Tuple, but as it's only consumed internally
      # we don't bother to save a little bit of memory and computation.
      defp convert_line(line) do
        line
        |> String.trim_trailing("\n")
        |> String.split("\t", [ parts: 2 ])
      end

      # This function handles the converted key/value pair coming from the prior
      # call to `convert_line/1`. We match on the previous key and the new key to
      # see if they belong in the same group; if they do, then we just add the
      # new value to the buffer of values. If it's a new key, we fire a `reduce/3`
      # call with the previous key and values and begin storing the new state.
      defp handle_convert([ key, val ], %Vessel{ group: { key, values } } = ctx) do
        ctx
        |> update_group(key, [ val | values ])
        |> update_count
      end
      defp handle_convert([ new_key, val ], %Vessel{ } = ctx) do
        ctx
        |> reduce_detect
        |> update_group(new_key, [ val ])
        |> update_count
      end

      # When we fire a reduction, we need to make sure that we have a valid group
      # of values and a key before calling reduce. This is because the very first
      # call to `reduce_detect/1` will not have a valid key/values pair due to no
      # previous input being provided (a.k.a. the initial state). We return the
      # Vessel context here just to make it more convenient to piepline our calls.
      defp reduce_detect(%Vessel{ group: { key, values } } = ctx) do
        reversed = Enum.reverse(values)

        key
        |> reduce(reversed, ctx)
        |> handle_return(ctx)
      end
      defp reduce_detect(ctx) do
        ctx
      end

      # Updates the count inside the Vessel context. This is just used to keep
      # track of the number of records which have been read by the current Vessel
      # job, because we use that to represent the initial mapping key.
      defp update_count(%Vessel{ count: count } = ctx) do
        %Vessel{ ctx | count: count + 1 }
      end

      # Updates the stored key grouping inside our Vessel context by placing the
      # provided key and values inside a Tuple and updating the struct's group.
      defp update_group(%Vessel{ } = ctx, key, values) do
        %Vessel{ ctx | group: { key, values } }
      end

      # We allow overriding reduce (obviously)
      defoverridable [ reduce: 3 ]
    end
  end

end
