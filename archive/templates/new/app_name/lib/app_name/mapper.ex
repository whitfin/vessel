defmodule <%= app_module %>.Mapper do
  @moduledoc """
  This module contains the implementation of the <%= app_module %> mapping phase.
  """
  use Vessel.Mapper

  # Invoked once before the first set of input is read.
  #
  # You can carry out any initial steps in this callback, and can modify the Job
  # context as required for your application logic.
  #
  # You may safely remove this callback if you have no custom logic implemented.
  def setup(context) do
    context
  end

  # Invoked for every key/value pair read in by the input stream.
  #
  # The value here will be your input, and the key simply a unique identifier
  # for each input value.
  #
  # This is where you should transform and emit your values as your business
  # logic requires. You can write values using `Vessel.write/2`.
  def map(_key, _value, context) do
    context
  end

  # Invoked once after the final set of input is read.
  #
  # This is the appropriate place to remove temporary files, close connections,
  # and any other cleanup operations which might be required.
  #
  # You may safely remove this callback if you have no custom logic implemented.
  def cleanup(context) do
    context
  end

end
