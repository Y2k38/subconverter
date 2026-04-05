defmodule Subconverter.ConfigLoader do
  @moduledoc """
  Responsible for dynamically fetching and initializing system configurations from various
  data sources (e.g., local .env, system environment variables, remote ETCD, etc.)
  before the OTP supervision tree starts.
  """

  def load do
    load_sources()
    configure_application()

    :ok
  end

  defp load_sources do
    # Phase 1: Fetch Raw Configurations (.env, ETCD, etc.)
    # First, we fetch from local sources (.env) and system environment variables,
    # converting everything into basic strings and injecting them into the OS level.
    import Dotenvy

    [".env", System.get_env()]
    |> source!()
    |> System.put_env()

    # (Reserved for ETCD or other remote configs)
    # Once the basic local env is set, we could use it to determine if we should fetch
    # remaining raw configs from a remote cluster.
    # if System.get_env("USE_ETCD") == "true" do
    #   remote_config = EtcdClient.fetch!("/subconverter/config")
    #   System.put_env(remote_config)
    # end
  end

  defp configure_application do
    # Phase 2: Configuration Extraction, Validation & Casting
    # Now that ALL raw string-based configurations are gathered in the OS layer,
    # we parse, validate, and crash early if critical variables are missing or invalid.
    port_str = System.get_env("PORT") || raise "PORT environment variable is missing!"

    port =
      case Integer.parse(port_str) do
        {num, ""} -> num
        _ -> raise "PORT environment variable must be a valid integer!"
      end

    # Phase 3: Commit to the Elixir Application Environment
    # Finally, save the strongly-typed, validated data into OTP's Application Env
    # so the rest of the app (e.g., application.ex, router.ex) can use it safely.
    Application.put_env(:subconverter, :port, port)

    secret_dir = System.get_env("SECRET_DIR") || raise "SECRET_DIR environment variable is missing!"
    Application.put_env(:subconverter, :secret_dir, secret_dir)
  end
end
