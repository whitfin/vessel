defmodule Mix.Tasks.Vessel.New do
  use Mix.Task

  # module constants
  @version  Mix.Project.config[:version]
  @shortdoc "Creates a new Vessel application"
  @switches [ app: :string, module: :string ]

  # file mappings
  @new [
    {:eex,  "new/app_name/config/config.exs",       "config/config.exs"},
    {:eex,  "new/app_name/lib/app_name/mapper.ex",  "lib/app_name/mapper.ex"},
    {:eex,  "new/app_name/lib/app_name/reducer.ex", "lib/app_name/reducer.ex"},
    {:eex,  "new/app_name/lib/app_name.ex",         "lib/app_name.ex"},
    {:eex,  "new/app_name/test/app_name_test.exs",  "test/app_name_test.exs"},
    {:text, "new/app_name/test/test_helper.exs",    "test/test_helper.exs"},
    {:text, "new/app_name/gitignore",               ".gitignore"},
    {:eex,  "new/app_name/mix.exs",                 "mix.exs"},
    {:eex,  "new/app_name/README.md",               "README.md"}
  ]

  # embed all defined templates
  root = Path.expand("../templates", __DIR__)

  # define all render functions
  for { _format, source, _target } <- @new do
    @external_resource Path.join(root, source)
    def render(unquote(source)), do: unquote(File.read!(Path.join(root, source)))
  end

  @moduledoc """
  Creates a new Vessel project.

  It expects the path of the project as argument.

      $ mix vessel.new PATH [--module MODULE] [--app APP]

  A project at the given PATH will be created. The
  application name and module name will be retrieved
  from the path, unless `--module` or `--app` is given.

  ## Options

    * `--app` - the name of the OTP application

    * `--module` - the name of the base module in
      the generated skeleton

  ## Examples

      $ mix vessel.new hello_world

  Is equivalent to:

      $ mix vessel.new hello_world --module HelloWorld

  """
  def run(argv) do
    check_elixir_version!(System.version())

    { opts, argv } =
      case OptionParser.parse(argv, [ strict: @switches ]) do
        { opts, argv, [] } ->
          { opts, argv }
        { _opts, _argv, [ switch | _ ] } ->
          Mix.raise("Invalid option: " <> switch_to_string(switch))
      end

    case argv do
      [] ->
        Mix.Tasks.Help.run([ "vessel.new" ])
      [ path | _ ] ->
        app = opts[:app] || Path.basename(Path.expand(path))
        mod = opts[:module] || Macro.camelize(app)

        check_application_name!(app, !!opts[:app])
        check_directory_existence!(app)
        check_module_name_validity!(mod)
        check_module_name_availability!(mod)

        exec(app, mod, path)
    end
  end

  # The main body of the templated copy, moving resources from the templated dir
  # and compiling them with EEx in order to replace the templated fields. We then
  # just copy the files across and spit out some instructions on what to do next.
  defp exec(app, mod, path) do
    version = Version.parse!(@version)

    binding = [
      app_name: app,
      app_module: mod,
      vessel_vsn: "#{version.major}.#{version.minor}"
    ]

    for { format, source, target_path } <- @new do
      replace = String.replace(target_path, "app_name", app)
      ren_src = render(source)

      content = case format do
        :text -> ren_src
        :eex  -> EEx.eval_string(ren_src, binding, [ file: source ])
      end

      path
      |> Path.join(replace)
      |> Mix.Generator.create_file(content)
    end

    msg =
      """

      We are all set! Compile your Vessel binaries:

          $ cd #{path}
          $ mix deps.get
          $ mix vessel.compile

      Any built binaries will be in rel/ by default.
      """

    Mix.shell.info(msg)
  end

  # Determines whether we have a valid application name or not. If we do then we
  # just continue, otherwise we raise an error to inform the user about how to
  # set a valid application name. We add an additional hint if name is inferred.
  defp check_application_name!(name, from_app_flag) do
    unless name =~ ~r/^[a-z][\w_]*$/ do
      extra = if from_app_flag do
        ""
      else
        ". The application name is inferred from the path, if you'd like to " <>
        "explicitly name the application then use the `--app APP` option."
        ""
      end

      Mix.raise("Application name must start with a letter and have only lowercase " <>
                "letters, numbers and underscore, got: #{inspect(name)}" <> extra)
    end
  end

  # Determines if this is a valid Elixir version to build against. Vessel requires
  # at least Elixir v1.1, so we just validate that for now. Most people will have
  # this, it's just here in case the requirement shifts in future (easy to change).
  defp check_elixir_version!(ver) do
    unless Version.match?(ver, "~> 1.1") do
      Mix.raise("Vessel v#{@version} requires at least Elixir v1.1.\n " <>
                "You have #{ver}. Please update accordingly")
    end
  end

  # Verifies that the name of the module is valid. This boils down to checking
  # that the first letter of each submodule is a capital followed by any word.
  defp check_module_name_validity!(name) do
    unless name =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/ do
      Mix.raise("Module name must be a valid Elixir alias " <>
                "(for example: Foo.Bar), got: #{inspect(name)}")
    end
  end

  # Verifies that the module name is not currently in use by any loaded module.
  # This is unlikely but exists in case you accidentally overwrite modules from
  # within the Elixir standard library (reasons should be fairly obvious).
  defp check_module_name_availability!(name) do
    loaded? =
      Elixir
      |> Module.concat(name)
      |> Code.ensure_loaded?

    if loaded? do
      Mix.raise("Module name #{inspect(name)} is already " <>
                "taken, please choose another name")
    end
  end

  # Verifies that the directory required does not already exist. If it does, we
  # prompt the user to check whether they want to write to the directory anyway.
  defp check_directory_existence!(name) do
    halt? =
      File.dir?(name)
        and not
      Mix.shell.yes?("The directory #{name} already exists." <>
                     "Are you sure you want to continue?")
    if halt? do
      Mix.raise("Please select another directory for installation.")
    end
  end

  # Just a small wrapper to convert a command line switch to String representation.
  # We have to special case the `nil` as otherwise we would get `key=`.
  defp switch_to_string({ name, nil }),
    do: name
  defp switch_to_string({ name, val }),
    do: name <> "=" <> val

end
