defmodule Subconverter.MixProject do
  use Mix.Project

  def project do
    [
      app: :subconverter,
      version: "0.1.5",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      escript: [main_module: Subconverter.CLI, name: "subconverter", app: nil]
    ]
  end

  def releases do
    # Force standard release via environment variable for testing purposes,
    # or fallback to checking if zig is installed.
    if System.get_env("FORCE_STANDARD_RELEASE") != "true" && System.find_executable("zig") do
      [
        subconverter_app: [
          steps: [:assemble, &Burrito.wrap/1, &compress_burrito/1],
          burrito: [
            targets: [
              linux: [os: :linux, cpu: :x86_64]
            ]
          ]
        ]
      ]
    else
      IO.puts("⚠️  Using standard Elixir Mix Release (Zig skipped or disabled)...")
      [subconverter_app: [steps: [:assemble, &compress_standard/1]]]
    end
  end

  defp compress_burrito(release) do
    version = release.version
    app_name = release.name
    burrito_opts = release.options[:burrito]

    if burrito_opts && burrito_opts[:targets] do
      Enum.each(burrito_opts[:targets], fn {target_alias, _} ->
        binary_name = "#{app_name}_#{target_alias}"
        binary_path = Path.join("burrito_out", binary_name)
        tar_gz_name = "#{app_name}_v#{version}_#{target_alias}.tar.gz"
        tar_gz_path = Path.join("burrito_out", tar_gz_name)

        if File.exists?(binary_path) do
          Mix.shell().info("📦 Compressing #{binary_name} → #{tar_gz_name} ...")
          {_out, 0} = System.cmd("tar", ["-czf", tar_gz_name, binary_name], cd: "burrito_out")
          write_checksum(tar_gz_path, tar_gz_name)
        end
      end)
    end

    release
  end

  defp compress_standard(release) do
    version = release.version
    app_name = release.name
    release_dir = Path.dirname(release.path)
    target_dir = Path.basename(release.path)
    tar_gz_name = "#{app_name}_v#{version}.tar.gz"
    tar_gz_path = Path.join(release_dir, tar_gz_name)

    if File.dir?(release.path) do
      Mix.shell().info("📦 Compressing #{target_dir} → #{tar_gz_name} ...")
      {_out, 0} = System.cmd("tar", ["-czf", tar_gz_name, target_dir], cd: release_dir)
      write_checksum(tar_gz_path, tar_gz_name)
    end

    release
  end

  defp write_checksum(tar_gz_path, tar_gz_name) do
    Mix.shell().info("🔐 Generating SHA256 checksum ...")

    hash_hex =
      tar_gz_path
      |> File.read!()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    File.write!(tar_gz_path <> ".sha256", "#{hash_hex}  #{tar_gz_name}\n")
    Mix.shell().info("✅ #{tar_gz_path}")
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
