# Vessel

Vessel is a set of interfaces to make working with Hadoop Streaming much easier from inside Elixir. Rather than dealing with Hadoop protocols directly, Vessel masks them and makes it simple via a straightforward API. Vessel also includes tools to setup Hadoop projects easily, as well as Mix tasks to make compiling your artifacts easy.

## Installation

Vessel is available on [Hex](https://hex.pm/). You can install the package via:

  1. Add vessel to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:vessel, "~> 0.1"}]
    end
    ```

  2. Ensure vessel is started before your application:

    ```elixir
    def application do
      [applications: [:vessel]]
    end
    ```

## Setup

Vessel is super simple to use and provides an archive containing a couple of Mix tasks to make your life easier, such as a Mix task to create a skeleton project.

You can install the latest archive using the commands below:

```bash
# If previously uninstalled
$ mix archive.install https://github.com/zackehh/vessel/archive/v0.1.0/vessel-archive-v0.1.0.ez

# Update a previous installation
$ mix local.vessel
```

## Project Generation

Vessel can be used in existing projects, but you'll typically want to create a new project designed just for Hadoop integration. A Vessel project is just a Mix project with a couple of things configured for you in advance, so you should be able to easily embed it inside things like Umbrella apps and so on.

You can create a Vessel project using the Mix task (after installing the archive as shown above).

```bash
# Look at options for the task
$ mix help vessel.new

# Generate a new Vessel project
$ mix vessel.new my_app
```

This will create a new project in the current directory named `my_app`. You can customize paths and other options just like other Mix project creation tasks (such as Phoenix's), just look at the task help documentation for more information.

If you look inside the `my_app` directory, you should see something similar to the following - as you can see, it's pretty simple.

```
.
├── config
│   └── config.exs
├── lib
│   ├── my_app
│   │   ├── mapper.ex
│   │   └── reducer.ex
│   └── my_app.ex
├── test
│   ├── my_app_test.exs
│   └── test_helper.exs
├── README.md
└── mix.exs
```

The files in `config/` and `test/` are everything you'd expect (the same as a typical Mix project). The files of note are those in `lib/` and `mix.exs`.

The generated `mix.exs` file will include the Vessel compiler definition, as well as some default Vessel compilation options inside `vessel/0`. These configurations are what you would have to setup manually when embedding Vessel into another project. They simply tell Vessel what it should compile into binaries (because the default escript compiler only builds one binary per project).

The files in `lib/` break down as follows:

- lib/my_app.ex
  - Just like a typical Mix project, generates an empty module for you to do usual stuff with.
- lib/my_app/(mapper|reducer).ex
  - This will contain your Mapper/Reducer for your Hadoop job.
  - Contains a template to get up and running more easily.
  - These modules are already configured to be compiled in `mix.exs`.

## Project Compilation

Once you have a project (either generated or created manually), you can compile your binaries. A generated project can be compiled with no additional changes, so feel free to compile straight away to see what happens:

```
# Move to the app
$ cd my_app

# Pull in Vessel deps
$ mix deps.get

# Compile!
$ mix compile
```

You should see some output similar to the following (it may change in future as the library evolves):

```
zackehh:/tmp/my_app$ mix compile
==> exscript
Compiling 1 file (.ex)
Generated exscript app
==> vessel
Compiling 6 files (.ex)
Generated vessel app
==> my_app
Compiling 3 files (.ex)
Generated my_app app
Generated escript ./rel/v0.1.0/my_app-mapper with MIX_ENV=dev
Generated escript ./rel/v0.1.0/my_app-reducer with MIX_ENV=dev
```

Looking at the last two lines, we can see that we now have two binaries inside the `rel/` directory which contain our mapper and reducer - these binaries can be used against Hadoop Streaming directly as defined [here](https://hadoop.apache.org/docs/r1.2.1/streaming.html).

You can customize the names of binaries and the target directory to by modifying the `:vessel` configuration in your `mix.exs` - see the `Mix.Tasks.Compile.Vessel` documentation for further information on how to go about this.
