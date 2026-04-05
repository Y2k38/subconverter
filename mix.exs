defmodule Subconverter.MixProject do
  use Mix.Project

  def project do
    [
      app: :subconverter,
      version: "0.1.2",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      escript: [main_module: Subconverter.CLI, name: "subconverter", app: nil]
    ]
  end

  def releases do
    if System.find_executable("zig") do
      [
        subconverter_app: [
          steps: [:assemble, &Burrito.wrap/1],
          burrito: [
            targets: [
              linux: [os: :linux, cpu: :x86_64]
            ]
          ]
        ]
      ]
    else
      IO.puts("⚠️  Zig compiler not found. Falling back to standard Elixir Mix Release...")
      [
        subconverter_app: []
      ]
    end
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets],
      mod: {Subconverter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:plug_cowboy, "~> 2.8"},
      {:bandit, "~> 1.10"},
      {:dotenvy, "~> 1.1"},
      {:burrito, "~> 1.5"},
      {:eqrcode, "~> 0.2.1"}
    ]
  end
end
