defmodule Vessel.ReducerTest do
  use ExUnit.Case, async: false

  # This test determines that we correctly call the lifecycle functions `setup/1`
  # and `cleanup/1` when working with a Vessel Reducer. We use a test Reducer which
  # just sets a flag to true at each point in the lifecycle to verify that we hit
  # the function and that it was executed correctly.
  test "lifecycle of a Vessel Reducer" do
    # consume an empty input
    ctx = Vessel.ReducerTest.Lifecycle.consume([])

    # retrieve the setup and cleanup flags
    setup = Vessel.get_private(ctx, :setup)
    clean = Vessel.get_private(ctx, :clean)

    # both should be set to true
    assert(setup == true)
    assert(clean == true)
  end

  # This test verifies that we can successfully reduce a grouping of inputs into
  # a list of output pairs. We verify this by running our test reducer against an
  # input and having writes directed to a Relay. We then just retrieve the Relay
  # contents and verify that they are correctly formed.
  test "reducing input groups to an output" do
    # create a new input stream
    input = [
      "key1\t1\n", "key1\t2\n", "key1\t3\n",
      "key2\t4\n", "key2\t5\n", "key2\t6\n",
      "key3\t7\n", "key3\t8\n", "key3\t9\n"
    ]

    # create a relay to catch output
    { :ok, relay } = Vessel.Relay.create()

    # consume the input stream
    Vessel.ReducerTest.Counter.consume(input, [ stdout: relay ])

    # retrieve the relay buffer
    result = Vessel.Relay.get(relay)

    # verify the written values
    assert(result == [
      "key1\t6\n",
      "key2\t15\n",
      "key3\t24\n"
    ])
  end

  # This test is similar to the one above, except we run in an environment which
  # enforces the use of a customer field separator using the environment flags as
  # specified in the Hadoop Streaming documentation. We again use a Relay to check
  # output, and make sure that the separators are correctly modified.
  test "reducing input groups to an output with custom separators" do
    # create a new input stream
    input = [
      "key1TAB1\n", "key1TAB2\n", "key1TAB3\n",
      "key2TAB4\n", "key2TAB5\n", "key2TAB6\n",
      "key3TAB7\n", "key3TAB8\n", "key3TAB9\n"
    ]

    # create a relay to catch output
    { :ok, relay } = Vessel.Relay.create()

    # set a custom field separator
    System.put_env("stream_reduce_input_field_separator",  "TAB")
    System.put_env("stream_reduce_output_field_separator", "BAT")

    # remove them when we're done
    on_exit(fn -> System.delete_env("stream_reduce_input_field_separator") end)
    on_exit(fn -> System.delete_env("stream_reduce_output_field_separator") end)

    # consume the input
    Vessel.ReducerTest.Counter.consume(input, [ stdout: relay ])

    # retrieve the relay buffer
    result = Vessel.Relay.get(relay)

    # verify the written values
    assert(result == [
      "key1BAT6\n",
      "key2BAT15\n",
      "key3BAT24\n"
    ])
  end

end

# Module support for the Lifecycle test case in the module above.
defmodule Vessel.ReducerTest.Lifecycle do
  use Vessel.Reducer

  # Sets the :setup flag in the context to true
  def setup(ctx),
    do: Vessel.put_private(ctx, :setup, true)

  # Sets the :clean flag in the context to true
  def cleanup(ctx),
    do: Vessel.put_private(ctx, :clean, true)
end

# Module support for the Counter test case in the module above.
defmodule Vessel.ReducerTest.Counter do
  use Vessel.Reducer

  # Emits the input key and a summed value from the values list
  def reduce(key, values, ctx),
    do: Vessel.write(ctx, { key, Enum.reduce(values, 0, &count/2) })

  # Shorthand to parse the left value and add it to the right
  defp count(value, total),
    do: String.to_integer(value) + total
end
