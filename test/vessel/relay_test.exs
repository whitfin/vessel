defmodule Vessel.RelayTest do
  use ExUnit.Case, async: false

  # This test case covers stopping and starting a Relay, which essentially boils
  # down to just making sure that we correctly pass things through to the Elixir
  # GenServer functions. Just doing due diligence to make sure it's covered.
  test "starting/stopping a Vessel Relay" do
    # create some relays to check options
    result1 = Vessel.Relay.create()
    result2 = Vessel.Relay.create([ name: :relay_test ])
    result3 = Vessel.Relay.create([ name: :relay_test ])

    # the first two should create
    assert(match?({ :ok, _pid }, result1))
    assert(match?({ :ok, _pid }, result2))

    # find the pid from the results
    { :ok, pid1 } = result1
    { :ok, pid2 } = result2

    # verify the third errors
    assert(result3 == { :error, { :already_started, pid2 } })

    # stop both of the relays
    result4 = Vessel.Relay.stop(pid1)
    result5 = Vessel.Relay.stop(pid2)

    # verify the result
    assert(result4 == :ok)
    assert(result5 == :ok)

    # ensure the process has gone
    refute(Process.alive?(pid1))
    refute(Process.alive?(pid2))
  end

  # Tests the various operations which can be handled in a Relay. Rather than
  # splitting this into many test cases, we just use a single one (to avoid the
  # need to keep re-seeding the Relay). We verify all of the main Relay actions,
  # including forwarding to this process and flushing the buffer.
  test "operating on a Vessel Relay" do
    # create our basic relay
    { :ok, relay } = Vessel.Relay.create()

    # define some messages
    message1 = "key1\tvalue1\n"
    message2 = "key2\tvalue2\n"
    message3 = "key3\tvalue3\n"

    # write some values to the relay
    IO.write(relay, message1)
    IO.write(relay, message2)

    # fake a multi IO request
    req_ref = make_ref()
    req_msg = { :requests, [ { :put_chars, :unicode, message3 } ] }
    request = { :io_request, self(), req_ref, req_msg }

    # send our fake requests
    send(relay, request)

    # we should receive an acknowledgement
    assert_receive({ :io_reply, ^req_ref, :ok })

    # verify forwarding to the current process
    :ok = Vessel.Relay.forward(relay)
    :ok = Vessel.Relay.forward(relay, self())

    # we should receive (ordered) messages
    assert_received({ :relay, ^message1 })
    assert_received({ :relay, ^message2 })
    assert_received({ :relay, ^message3 })
    assert_received({ :relay, ^message1 })
    assert_received({ :relay, ^message2 })
    assert_received({ :relay, ^message3 })

    # test basic retrieval functionss
    result1 = Vessel.Relay.get(relay)
    result2 = Vessel.Relay.raw(relay)
    result3 = Vessel.Relay.sort(relay, &>/2)
    result4 = Vessel.Relay.sort(relay)

    # the first is ordered, second not
    assert(result1 == [ message1, message2, message3 ])
    assert(result2 == [ message3, message2, message1 ])
    assert(result3 == [ message3, message2, message1 ])
    assert(result4 == [ message1, message2, message3 ])

    # verify that we can flush messages
    :ok = Vessel.Relay.flush(relay)

    # retrieve the raw messages again
    result4 = Vessel.Relay.raw(relay)

    # they should be empty
    assert(result4 == [])
  end

end
