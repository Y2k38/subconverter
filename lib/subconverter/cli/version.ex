defmodule Subconverter.CLI.Version do
  @moduledoc """
  Handles the `version` command.
  """

  @version Mix.Project.config()[:version]

  def run([]) do
    IO.puts("Subconverter v#{@version}")
  end

  def run(_) do
    IO.puts("❌ Error: 'version' command does not accept additional arguments.")
  end
end
