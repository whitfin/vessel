# Vessel
[![Build Status](https://img.shields.io/travis/zackehh/vessel.svg?maxAge=900000)](https://travis-ci.org/zackehh/vessel) [![Coverage Status](https://img.shields.io/coveralls/zackehh/vessel.svg?maxAge=900000)](https://coveralls.io/github/zackehh/vessel) [![Hex.pm Version](https://img.shields.io/hexpm/v/vessel.svg?maxAge=900000)](https://hex.pm/packages/vessel) [![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://hexdocs.pm/vessel/)

Vessel is a MapReduce framework for Elixir, with support for Hadoop Streaming. Rather than dealing with Hadoop protocols directly, Vessel masks them and makes it simple via a straightforward API. Vessel also includes tools to setup Hadoop projects easily, as well as Mix tasks to make compiling your artifacts easy. Although the aim is to build for Hadoop, you can also use Vessel in your own (non-Hadoop) projects, or as binary executables for use in command line environments.

**Disclaimer:** *Vessel is currently in a pre-v1 state, meaning that the API may still change at any point. Although I will do my best to avoid this happening, please be aware that it may be forced to happen - so test thoroughly if you update your Vessel dependency. The v0.x versioning signifies that Vessel is not feature complete enough to be classified (in my opinion) as a v1.x, rather than it being an unstable or buggy codebase.*

## Installation

Vessel is available on [Hex](https://hex.pm/). You can install the package via:

  1. Add vessel to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:vessel, "~> 0.8"}]
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
$ mix archive.install https://github.com/zackehh/vessel/releases/download/v0.8.0/vessel_arch-0.8.0.ez

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

# Compile your binaries
$ mix vessel.compile
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

You can customize the names of binaries and the target directory to by modifying the `:vessel` configuration in your `mix.exs` - see the `Mix.Tasks.Vessel.Compile` documentation for further information on how to go about this.

## Project Testing

The best way to test your jobs is just with small input files. You don't need to have a running Hadoop installation; you can use the following to replicate the Hadoop behaviour. This will just pipe everything together in the same way that Hadoop would using standard UNIX sorting (obviously tweak your `sort` arguments to match whatever you might use with Hadoop sorting).

```bash
# Testing syntax, with a typical sort - combiner optional
$ cat <input> | <mapper> | sort -k1,1 | <combiner> | <reducer>

# Example usage (taken from the wordcount example)
$ cat resources/input.txt | ./rel/v0.1.0/wordcount-mapper | sort -k1,1 | ./rel/v0.1.0/wordcount-reducer
```

I have also added a module named `Vessel.Relay` which acts as a dummy IO stream. You can use this module in unit tests to verify your projects, as it will capture the outputs written to the context. You can find examples of how to use the Relay inside the Vessel test cases for `Vessel.Mapper` and `Vessel.Reducer`, or by visiting the documentation.

## Important Notes

There are a number of things to be aware of so I'm going to detail them here, for want of a better place. You should make sure to read through this at least once before using Vessel.

1. Erlang buffers the entirety of `:stdin` even before it's requested - this means that the memory in your tasks must be sufficient to buffer the entirety of your input. There is absolutely nothing I can do about this beyond document it at the moment (as it's Erlang behaviour rather than Vessel itself). Make sure you tune the memory for your tasks accordingly, or split your files up further. For reference my test dataset, which consists of files anywhere from 100-150MB of GZIP compressed log data (JSON), required around 3GB memory per Mapper.

  Tuning these options can be done via the `mapreduce.map.memory.mb` and `mapreduce.reduce.memory.mb` Hadoop options, both which take a number (in MBs) as a value. A general rule of thumb (as observed in the wild) seems to be that your Reducer should have ~2x the memory of your Mapper - and you should make good use of Combiners when applicable. You can also lower the split sizes of your files to avoid changing your memory allocation, but I'm not sure enough on how to do this to document it - if anyone does, feel free to PR this README to add a note!

  In the background, I'm trying to figure out how to make Vessel operate without a need to think about memory allocation - perhaps through some bindings which relay `:stdin` on demand to the Erlang process. This is admittedly a bit out of my depth at this point, so I'm not entirely sure when/if this might make it into the project. Ideas are welcome!

2. I have run several simple jobs on Amazon EMR using the dataset outlined above and everything seems to work quickly, and it's close enough to typical Java jobs that I can't really tell what the difference is in speed - it certainly doesn't feel slower, for what it's worth.

  There may be a little sluggishness to begin with due to the memory overhead described above but a little extra memory would solve this fairly easily. In future, I may even add a handler to Vessel to make sure that a warning is emitted one the peak of `:stdin` has been detected, in order to inform you roughly how much memory you're going to want.

3. Combiners are fully supported as they are just Reducers. You can add a `:combiner` compilation target to your `:vessel` declaration in your `mix.exs` to compile a Combiner. I have made sure to test that both compilation and running a Combiner works in actuality. The example `wordcount` contains an example of combiner usage.

4. Every time compilation is invoked with Mix, your binaries will be rebuilt (go ahead and try `mix compile`). If you wish to turn this off, you can remove the `:vessel` compiler from within your `mix.exs`. This will remove automatic compilation and require you to run the task `mix vessel.compile` in order to create your binaries.

5. You can safely use Vessel outside of Hadoop Streaming, as it just accepts `:stdin` and writes to `:stdio`. This means that you can use Vessel to write computation tools for command line use as well as alongside Hadoop. You can even use it from within your own OTP application via the `consume/2` interface, although you would have to hook up your own `Vessel.Relay` to deal with the output (or any other process which can handle the IO protocol).

6. Vessel binaries require Erlang to be installed on the nodes they're running on. This should be fairly evident, but I'm pointing it out just in case as I was once guilty of being unaware - your binaries are just Erlang `escript` files which do not have Erlang embedded within (I really wish they did, imagine what you could do with that!). They do not require Elixir be installed, as that *is* bundled into the binary.
