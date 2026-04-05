defmodule Subconverter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Abstracted configuration loading center:
    # It dynamically loads (.env, etcd), validates, and caches configs into
    # the Application environment before starting any services.
    Subconverter.ConfigLoader.load()

    # Safely fetch the pre-validated configurations (guaranteed to exist and be correct due to ConfigLoader)
    port = Application.fetch_env!(:subconverter, :port)

    children = [
      # Starts a worker by calling: Subconverter.Worker.start_link(arg)
      # {Subconverter.Worker, arg}
      {Bandit, plug: Subconverter.Router, scheme: :http, port: port}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Subconverter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
