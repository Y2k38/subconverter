defmodule Subconverter.CLI do
  @moduledoc """
  Command-line interface entry point.
  Acts as a command dispatcher, routing subcommands to their respective modules.
  """

  def main(args) do
    case args do
      ["export" | options] ->
        Subconverter.CLI.Export.run(options)

      ["version" | options] ->
        Subconverter.CLI.Version.run(options)

      ["help"] ->
        print_help()

      [] ->
        print_help()

      _ ->
        IO.puts("❌ Error: Unknown command.\n")
        print_help()
    end
  end

  defp print_help do
    IO.puts("""
    Subconverter CLI Tool

    Usage:
      subconverter <command> [options]

    Available Commands:
      export       Export node configuration as URL or QRCode for specific clients
      version      Print the current version of Subconverter

    Additional Help:
      subconverter <command> help

    Example:
      subconverter export help
    """)
  end
end
