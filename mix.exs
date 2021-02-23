defmodule Vessel.Mixfile do
  use Mix.Project

  # Link constants
  @url_docs "http://hexdocs.pm/vessel"
  @url_github "https://github.com/zackehh/vessel"

  # Base project configuration properties for Hex.pm
  #
  # See https://hex.pm/docs/publish for more information
  def project do
    [
      app: :vessel,
      name: "Vessel",
      description: "Elixir MapReduce interfaces with Hadoop Streaming integration",
      package: %{
        files: [
          "config",
          "lib",
          "mix.exs",
          "LICENSE",
          "README.md"
        ],
        licenses: [ "MIT" ],
        links: %{
          "Docs" => @url_docs,
          "GitHub" => @url_github
        },
        maintainers: [ "Isaac Whitfield" ]
      },
      version: "0.8.0",
      elixir: "~> 1.3",
      deps: deps(),
      docs: [
        extras: [ "README.md" ],
        source_ref: "master",
        source_url: @url_github
      ],
      test_coverage: [ tool: ExCoveralls ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :exscript]]
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
    [
      # Production dependencies
      { :exscript, "~> 0.1" },
      # Development dependencies
      { :benchfella,  "~> 0.3",  optional: true, only: [ :dev, :test ] },
      { :credo,       "~> 1.5",  optional: true, only: [ :dev, :test ] },
      { :ex_doc,      "~> 0.14", optional: true, only: [ :dev, :test ] },
      { :excoveralls, "~> 0.13", optional: true, only: [ :dev, :test ] }
    ]
  end
end
