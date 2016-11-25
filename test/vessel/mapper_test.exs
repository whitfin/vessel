defmodule Vessel.MapperTest do
  use ExUnit.Case, async: false

  # This test determines that we correctly call the lifecycle functions `setup/1`
  # and `cleanup/1` when working with a Vessel Mapper. We use a test Mapper which
  # just sets a flag to true at each point in the lifecycle to verify that we hit
  # the function and that it was executed correctly.
  test "lifecycle of a Vessel Mapper" do
    # consume an empty input
    ctx = __MODULE__.Lifecycle.consume([])

    # retrieve the setup and cleanup flags
    setup = Vessel.get_private(ctx, :setup)
    clean = Vessel.get_private(ctx, :clean)

    # both should be set to true
    assert(setup == true)
    assert(clean == true)
  end

  # This test verifies that we can successfully map an input stream to a set of
  # output pairs. We verify this by passing the input to a test mapper which
  # converts the input to upper case and emits the input key against the new value.
  # We capture the output with a Relay, and verify that the records are written
  # correctly to the Relay (which acts as mock stdout).
  test "mapping inputs to outputs" do
    # create a new input stream
    input = [ "one", "two", "three" ]

    # create a relay to catch output
    { :ok, relay } = Vessel.Relay.create()

    # consume the input stream
    __MODULE__.Counter.consume(input, [ stdout: relay ])

    # retrieve the relay buffer
    result = Vessel.Relay.get(relay)

    # verify the written values
    assert(result == [
      "1\tONE\n",
      "2\tTWO\n",
      "3\tTHREE\n"
    ])
  end

  # This test is similar to the one above, except we run in an environment which
  # enforces the use of a customer field separator using the environment flags as
  # specified in the Hadoop Streaming documentation. We again use a Relay to check
  # output, and make sure that the separators are correctly modified.
  test "mapping inputs to outputs with custom separators" do
    # create a new input stream
    input = [ "one", "two", "three" ]

    # create a relay to catch output
    { :ok, relay } = Vessel.Relay.create()

    # set a custom field separator
    System.put_env("stream_map_output_field_separator", "TAB")

    # remove it when we're done
    on_exit(fn -> System.delete_env("stream_map_output_field_separator") end)

    # consume the input
    __MODULE__.Counter.consume(input, [ stdout: relay ])

    # retrieve the relay buffer
    result = Vessel.Relay.get(relay)

    # verify the written values
    assert(result == [
      "1TABONE\n",
      "2TABTWO\n",
      "3TABTHREE\n"
    ])
  end

end

# Module support for the Lifecycle test case in the module above.
defmodule Vessel.MapperTest.Lifecycle do
  use Vessel.Mapper

  # Sets the :setup flag in the context to true
  def setup(ctx),
    do: Vessel.put_private(ctx, :setup, true)

  # Sets the :clean flag in the context to true
  def cleanup(ctx),
    do: Vessel.put_private(ctx, :clean, true)
end

# Module support for the Counter test case in the module above.
defmodule Vessel.MapperTest.Counter do
  use Vessel.Mapper

  # Emits the key with an uppercase value
  def map(key, value, ctx),
    do: Vessel.write(ctx, { key, String.upcase(value) })
end
