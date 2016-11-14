defmodule <%= app_module %>.Mixfile do
  use Mix.Project

  def project do
    [app: :<%= app_name %>,
     version: "0.1.0",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     compilers: Mix.compilers() ++ [:vessel],
     deps: deps(),
     vessel: vessel()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:vessel, "~> <%= vessel_vsn %>"}]
  end

  # Vessel configuration properties
  defp vessel do
    [{:mapper,  [ module: <%= app_module %>.Mapper  ]},
     {:reducer, [ module: <%= app_module %>.Reducer ]}]
  end
end
