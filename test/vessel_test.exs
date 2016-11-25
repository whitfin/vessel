defmodule VesselTest do
  use ExUnit.Case, async: false

  # This test covers the construction of a Vessel context using options such as
  # custom metadata and custom configurations. We make sure that custom values
  # are kept inside the struct, and that a configuration is generated if there
  # isn't a custom configuration set on creation.
  test "constructing a Vessel context" do
    # create some differing context
    context1 = Vessel.context()
    context2 = Vessel.context([ meta: [ ] ])
    context3 = Vessel.context([ conf: [ ] ])

    # create some expected context
    expected1 = %Vessel{ conf: Vessel.Conf.new() }
    expected2 = %Vessel{ conf: Vessel.Conf.new(), meta: [ ] }
    expected3 = %Vessel{ conf: [ ] }

    # verify matching across the board
    assert(context1 == expected1)
    assert(context2 == expected2)
    assert(context3 == expected3)
  end

  # This test case makes sure that we can correctly inspect values using a context,
  # making sure that the context can be provided as the first or second argument
  # (for chaining), and that we can pass options to the inspection.
  test "inspecting values via Vessel" do
    # create a relay to swallow output
    { :ok, stderr } = Vessel.Relay.create()

    # create a context with the relay
    context = Vessel.context([ stderr: stderr ])

    # inspect some values
    [ 1, 2, 3 ] = Vessel.inspect(context, [ 1, 2, 3 ])
    [ 1, 2, 3 ] = Vessel.inspect([ 1, 2, 3 ], context)
    [ 1, 2, 3 ] = Vessel.inspect(context, [ 1, 2, 3 ], [ limit: 1 ])

    # forward the relay messages
    :ok = Vessel.Relay.forward(stderr)

    # assert we receive all logs
    assert_received({ :relay, "[1, 2, 3]\n" })
    assert_received({ :relay, "[1, 2, 3]\n" })
    assert_received({ :relay, "[1, ...]\n" })
  end

  # This test makes sure that we can correctly log messages out to the context.
  # We make sure that binary messages work, and values which do not implement
  # String.Chars cause an error. This is to keep compatible with the style of
  # `IO.puts/1` and `IO.inspect/1`, to avoid surprises.
  test "logging messages via Vessel" do
    # create a relay to swallow output
    { :ok, stderr } = Vessel.Relay.create()

    # create a context with the relay
    context = Vessel.context([ stderr: stderr ])

    # log out some values
    :ok = Vessel.log(context, "Hello, from the Relay!")
    :ok = Vessel.log(context, 'Hello, from the Relay!')

    # forward the relay messages
    :ok = Vessel.Relay.forward(stderr)

    # assert we receive all logs
    assert_received({ :relay, "Hello, from the Relay!\n" })
    assert_received({ :relay, "Hello, from the Relay!\n" })

    # check that invalid values cause errors
    assert_raise(Protocol.UndefinedError, fn ->
      Vessel.log(context, %{ })
    end)
  end

  # This test covers the modification of a Vessel context by using the modify
  # function. We check that modification takes effect, and that trying to modify
  # a missing key will cause a KeyError. This is to avoid bloating the struct.
  test "modifying fields in a context" do
    # construct a basic context
    context = Vessel.context()

    # modify an existing key
    result1 = Vessel.modify(context, :args, 5)

    # verify the change occurred
    assert(result1.args == 5)

    # ensure missing keys cause errors
    assert_raise(KeyError, fn ->
      Vessel.modify(context, :missing, 5)
    end)
  end

  # This test covers the interaction with the Hadoop Streaming Job counters/status
  # to make sure that we can correctly modify them. This test can only capture
  # the output and make sure that we receive correctly formatter output.
  test "updating Job metadata via Vessel" do
    # create a relay to swallow output
    { :ok, stderr } = Vessel.Relay.create()

    # create a context with the relay
    context = Vessel.context([ stderr: stderr ])

    # update counters and status
    :ok = Vessel.update_counter(context, "vessel", "test_counter")
    :ok = Vessel.update_counter(context, "vessel", "test_counter", 5)
    :ok = Vessel.update_status(context, "warning")

    # forward the relay messages
    :ok = Vessel.Relay.forward(stderr)

    # assert we receive all logs
    assert_received({ :relay, "reporter:counter:vessel,test_counter,1\n" })
    assert_received({ :relay, "reporter:counter:vessel,test_counter,5\n" })
    assert_received({ :relay, "reporter:status:warning\n" })
  end

  # This test just makes sure that we can correctly set and retrieve configuration
  # properties. We make sure that all dots are converted to underscores, to keep
  # in line with the Hadoop configuration whilst masking the changes from the
  # user (to avoid unexpected issues).
  test "working with configuration properties" do
    # construct a basic context
    context = Vessel.context([ conf: %{ } ])

    # place some values into the context
    context = Vessel.put_conf(context, "something.something", 1)
    context = Vessel.put_conf(context, "dark_side", 1)

    # retrieve the values from the context
    result1 = Vessel.get_conf(context, "something_something")
    result2 = Vessel.get_conf(context, "dark.side")
    result3 = Vessel.get_conf(context, "missing")
    result4 = Vessel.get_conf(context, "missing", 2)

    # verify dots don't matter
    assert(result1 == 1)
    assert(result2 == 1)

    # verify defaulting
    assert(result3 == nil)
    assert(result4 == 2)
  end

  # Another test case like the above, except this time covering the ability to
  # set/retrieve values from inside the metadata map. This is only used internally
  # and there are no changes made to the provided keys (i.e. they're stored as is).
  test "working with metadata properties" do
    # construct a basic context
    context = Vessel.context()

    # place some values into the context
    context = Vessel.put_meta(context, :separators, { "\t", "\t" })

    # retrieve the values from the context
    result1 = Vessel.get_meta(context, :separators)
    result2 = Vessel.get_meta(context, :missing)
    result3 = Vessel.get_meta(context, :missing, 1)

    # verify retrieval
    assert(result1 == { "\t", "\t" })

    # verify defaulting
    assert(result2 == nil)
    assert(result3 == 1)
  end

  # One more test case like the above, except this time covering the ability to
  # set/retrieve values from inside the private map. This is used by end-users
  # and so there are zero restrictions on what can go inside this map.
  test "working with private storage" do
    # construct a basic context
    context = Vessel.context()

    # place some values into the context
    context = Vessel.put_private(context, :separators, { "\t", "\t" })

    # retrieve the values from the context
    result1 = Vessel.get_private(context, :separators)
    result2 = Vessel.get_private(context, :missing)
    result3 = Vessel.get_private(context, :missing, 1)

    # verify retrieval
    assert(result1 == { "\t", "\t" })

    # verify defaulting
    assert(result2 == nil)
    assert(result3 == 1)
  end

  # This test covers that we can correctly write values out to a context and that
  # the separators are correctly used, along with the specified output streams.
  test "writing via a Vessel context" do
    # create a relay to swallow output
    { :ok, stdout } = Vessel.Relay.create()

    # create a context with the relay
    context1 = Vessel.context([ stdout: stdout ])
    context2 = Vessel.context([
      meta: %{ separators: { "\s", "\s" } },
      stdout: stdout
    ])

    # write values to the context
    :ok = Vessel.write(context1, { "key", "12345" })
    :ok = Vessel.write(context1, { "key",  12345  })
    :ok = Vessel.write(context2, "key", "12345")
    :ok = Vessel.write(context2, "key",  12345 )

    # forward the relay messages
    :ok = Vessel.Relay.forward(stdout)

    # assert we receive all pairs
    assert_received({ :relay, "key\t12345\n" })
    assert_received({ :relay, "key\t12345\n" })
    assert_received({ :relay, "key\s12345\n" })
    assert_received({ :relay, "key\s12345\n" })
  end

end
