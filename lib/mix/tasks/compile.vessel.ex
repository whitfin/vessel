defmodule Mix.Tasks.Compile.Vessel do
  @moduledoc """
  Compiles a set of Vessel binaries.

  This module lives purely to allow the use of the `:vessel` compiler in your
  Mix definition.

  Adding `:vessel` to the end of your compilers list will automatically build
  your binaries when you compile, rather than forcing you to build them manually.

  Rather than re-implement everything, we just use the definitions from inside
  `Mix.Tasks.Vessel.Compile` to make sure we stay in-sync.
  """
  defdelegate run(args),
    to: Mix.Tasks.Vessel.Compile

end
