defmodule Mix.Tasks.Compile.Vessel do
  @moduledoc """
  Compiles a set of Vessel binaries.

  The binaries to compile are dictated by the `:vessel` property inside the Mix
  project definition. The property should be a Keyword List containing a subset
  of the keys `:mapper`, `:combiner` and `:reducer`.

  Each of these keys may have options provided as to where to build the binary
  to, and the module which should act as the entry point:

      [ mapper: [ module: MyMapper, output: "./binaries/mapper" ] ]

  If you don't provide an `:output` property, it will be placed in `target/` with
  a name of the form `{app_name}-{type}`, for example `my_app-mapper`.

  If you don't wish to customise the output, you can just set the properties as
  an Atom and it will be used as the module name:

      [ mapper: MyMapper ] # unpacks to [ mapper: [ module: MyMapper ] ]

  If your module name is not provided, the binary will be ignored - however if
  your module is invalid, an error will be raised.
  """

  # mix task
  use Mix.Task

  # different Vessel build phases
  @phases [ :mapper, :combiner, :reducer ]

  @doc """
  Callback implementation for `Mix.Task.run/1`.
  """
  def run(args) do
    Mix.Project.get!()
    Mix.Task.run("compile", args)

    project = Mix.Project.config()
    vessel  = Keyword.get(project, :vessel, [])

    for phase <- @phases do
      opts = case Keyword.get(vessel, phase) do
        nil -> []
        val -> ensure_opts!(val, phase)
      end

      case Keyword.get(opts, :module) do
        nil -> nil
        mod -> build!(project, mod, opts, phase)
      end
    end
  end

  # Carries out a build for a given phase using the provided module definition
  # and options. This is basically a delegation function to `Exscript` under the
  # hood, just with a couple of options defined automatically (e.g. target).
  defp build!(project, module, options, phase) do
    ensure_module!(module, phase)

    app  = Keyword.get(project, :app)
    out  = Keyword.get(options, :output, "./target/#{app}-#{phase}")

    name = String.to_atom("#{app}_#{phase}")
    opts = [ app: name, path: out, main_module: module ]

    Exscript.escriptize(project, :elixir, opts, true, true)
  end

  # Verifies that a module designation is a correct Vessel module and exists in
  # the bounds of a compilation pass. If it does not, we raise an error with a
  # prompt about Vessel inheritance, in case they simply missed the `use` clause.
  defp ensure_module!(module, phase) do
    loaded? = Code.ensure_loaded?(module)
    vessel? = :erlang.function_exported(module, :main, 1)

    unless loaded? and vessel? do
      hmod = String.trim_leading("#{module}", "Elixir.")
      hves = vessel_type(phase)

      Mix.raise("Could not generate Vessel binary, please ensure that " <>
                "#{hmod} exists and correctly includes `use #{hves}`")
    end
  end

  # Validates the format of options provided for a Vessel phase. We convert any
  # lone Atoms to a List, against the `:module` key. Any Lists are kept as-is,
  # and anything else will raise an error message.
  defp ensure_opts!(val, _phase) when is_atom(val),
    do: [ module: val ]
  defp ensure_opts!(val, _phase) when is_list(val),
    do: val
  defp ensure_opts!(_val, phase),
    do: Mix.raise("Invalid Vessel option provided for key :#{phase}")

  # Converts a phase name to the correct Elixir module name representation. This
  # will convert `:combiner` to `Mapper.Reducer` as combiners inherit Reducers.
  defp vessel_type(:mapper), do: "Vessel.Mapper"
  defp vessel_type(_module), do: "Vessel.Reducer"

end
