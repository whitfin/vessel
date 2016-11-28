defmodule Wordcount.Mixfile do
  use Mix.Project

  def project do
    [app: :wordcount,
     version: "0.1.0",
     elixir: "~> 1.3",
     compilers: Mix.compilers() ++ [:vessel],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
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
    [{:vessel, path: "../../"}]
  end

  # Vessel configuration properties
  defp vessel do
    [{:mapper,  [ module: Wordcount.Mapper  ]},
     {:reducer, [ module: Wordcount.Reducer ]}]
  end
end
