defmodule Vessel.ConfTest do
  use ExUnit.Case, async: false

  # This test ensures that we only receive Streaming variables in the config.
  # This is hard to judge, but basically Streaming values are always lower-cased
  # and never contain a `.`, so we just make sure they're filtered out properly.
  test "filtering of non-streaming values" do
    # define an environment modifier
    env_assign = fn(key, value) ->
      # add the key and value pair
      System.put_env(key, value)
      # schedule their removal on exit
      on_exit("cleanup #{key}", fn ->
        System.delete_env(key)
      end)
    end

    # add keys which should be ignored
    env_assign.("FAKE_VAR", "1")
    env_assign.("mapred.job.id", "123")

    # add a key which should be kept
    env_assign.("mapred_job_id", "123")

    # generate a configuration
    conf = Vessel.Conf.new()

    # the first two should be missing
    refute(Map.has_key?(conf, "FAKE_VAR"))
    refute(Map.has_key?(conf, "mapred.job.id"))

    # the third should be kept and the value stored
    assert(Map.get(conf, "mapred_job_id") == "123")
  end

end
