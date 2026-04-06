defmodule Subconverter.Handlers.Subscription do
  @moduledoc """
  Handles the subscription endpoint.
  Resolves the config file path based on the client's User-Agent and serves
  it with proper HTTP caching headers (ETag / Last-Modified).
  """

  use Plug.Router
  import Plug.Conn

  plug :match
  plug :dispatch

  # Maps known User-Agent substrings to their corresponding config filenames.
  @ua_map %{
    "clash" => "clash.txt",
    "shadowrocket" => "shadowrocket.txt"
  }

  get "/:user_id/:token" do
    # TODO: Validate user_id and token against a secrets store.
    # Note: Path parameters matched in the router (such as user_id and token) are already bound as variables here.
    ua =
      conn
      |> get_req_header("user-agent")
      |> List.first()
      |> to_string()
      |> String.downcase()

    secret_dir = Application.fetch_env!(:subconverter, :secret_dir)

    # Add anti-browser/search engine headers to prevent crawling.
    conn = put_resp_header(conn, "x-robots-tag", "noindex, nofollow")

    case resolve_filename(ua, secret_dir) do
      nil ->
        send_resp(conn, 404, "Not Found")

      filename ->
        serve_file(conn, filename)
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp resolve_filename(ua, secret_dir) do
    Enum.find_value(@ua_map, fn {ua_fragment, config_file} ->
      if String.contains?(ua, ua_fragment) do
        Path.join(secret_dir, config_file)
      end
    end)
  end

  defp serve_file(conn, filename) do
    case File.stat(filename, time: :universal) do
      {:error, _} ->
        send_resp(conn, 500, "Internal Server Error: Resource not configured")

      {:ok, stat} ->
        # Note: :httpd_util belongs to :inets. Ensure it is listed in extra_applications.
        etag = "\"#{stat.size}-#{:erlang.phash2(stat.mtime)}\""
        last_modified = :httpd_util.rfc1123_date(stat.mtime) |> to_string()

        req_etag = conn |> get_req_header("if-none-match") |> List.first()
        req_last_mod = conn |> get_req_header("if-modified-since") |> List.first()

        if req_etag == etag or req_last_mod == last_modified do
          send_resp(conn, 304, "")
        else
          case File.read(filename) do
            {:error, _} ->
              send_resp(conn, 500, "Internal Server Error: Resource not configured")

            {:ok, content} ->
              conn
              |> put_resp_header("etag", etag)
              |> put_resp_header("last-modified", last_modified)
              |> send_resp(200, content)
          end
        end
    end
  end
end
