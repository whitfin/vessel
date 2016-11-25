defmodule Vessel.IOTest do
  use ExUnit.Case, async: false

  # This test verifies that we can successfully split input lines into a pairing
  # of a key and a value, per the Hadoop Streaming documentation. This includes
  # adhering to the specification that respects arbitrary numbers of key fields,
  # which controls where exactly we split the value. We make sure to verify that
  # we drop trailing newlines, and that we don't error on high field counts.
  test "splitting binaries into keys and values" do
    # define our input binary
    input = "this.is.a.test.entry\n"

    # test various field count combinations
    result1 = Vessel.IO.split(input, ".", 1)
    result2 = Vessel.IO.split(input, ".", 2)
    result3 = Vessel.IO.split(input, ".", 3)
    result4 = Vessel.IO.split(input, ".", 4)
    result5 = Vessel.IO.split(input, ".", 5)
    result6 = Vessel.IO.split(input, ".", 6)

    # verify the key/value pairings are generated
    assert(result1 == { "this",  "is.a.test.entry" })
    assert(result2 == { "this.is",  "a.test.entry" })
    assert(result3 == { "this.is.a",  "test.entry" })
    assert(result4 == { "this.is.a.test",  "entry" })
    assert(result5 == { "this.is.a.test.entry", "" })
    assert(result6 == { "this.is.a.test.entry", "" })
  end

  # This test uses Relays to check that we are correctly writing to stdout and
  # stderr when using the IO module to write messages. We verify that the messages
  # are correctly received by the Relay and can be returned. This is sufficient
  # as the Relay module adheres to the IO protocol, so we can be sure messages
  # being sent are appropriately formed (otherwise it would error).
  test "writing out to stdout and stderr" do
    # define a relay to capture output
    { :ok, stdout } = Vessel.Relay.create()
    { :ok, stderr } = Vessel.Relay.create()

    # construct a context with redirected output
    context = Vessel.context([ stdout: stdout, stderr: stderr ])

    # define our messages to send through
    stdout_msg = "key\tvalue\n"
    stderr_msg = "my_outputs\n"

    # write some output for both streams
    Vessel.IO.stdout(context, stdout_msg)
    Vessel.IO.stderr(context, stderr_msg)

    # retrieve the relay outputs
    stdout_result = Vessel.Relay.get(stdout)
    stderr_result = Vessel.Relay.get(stderr)

    # verify both outputs are received
    assert(stdout_result == [ stdout_msg ])
    assert(stderr_result == [ stderr_msg ])
  end

end
