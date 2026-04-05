defmodule Subconverter.Plugs.RequestLogger do
  @moduledoc """
  A plug that logs the client IP, HTTP method, request path, and User-Agent
  for every incoming request.

  Example output:
      12:34:56.789 [info] 127.0.0.1 "GET /subscribe/..." "Clash/1.9.0"
  """

  require Logger
  import Plug.Conn

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    # Remote IP is a tuple like {127, 0, 0, 1}; :inet.ntoa/1 formats it as a string.
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    ua = conn |> get_req_header("user-agent") |> List.first() || "-"

    Logger.info("#{ip} \"#{conn.method} #{conn.request_path}\" \"#{ua}\"")

    conn
  end
end
