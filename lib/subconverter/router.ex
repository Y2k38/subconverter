defmodule Subconverter.Router do
  use Plug.Router
  require Logger

  # Execute our custom logging plug for ALL requests
  plug :log_request
  plug :match
  plug :dispatch

  get "/subscribe/:user_id/:token" do
    # TODO: User authentication and token verification

    ua = get_req_header(conn, "user-agent") |> List.first() |> to_string() |> String.trim() |> String.downcase()

    # Get the base directory from the environment variable (e.g., loaded from .env)
    # Fallback to current directory (".") if not set
    base_dir = System.get_env("CONFIG_DIR") || "."

    # Add anti-browser/search engine headers to prevent crawling
    conn = put_resp_header(conn, "x-robots-tag", "noindex, nofollow")

    filename =
      cond do
        String.contains?(ua, "clash") ->
          Path.join(base_dir, "clash.txt")

        String.contains?(ua, "shadowrocket") ->
          Path.join(base_dir, "shadowrocket.txt")

        # Refuse to serve content to unknown User-Agents (scanners, browsers, etc.)
        true ->
          nil
      end

    if is_nil(filename) do
      # Instantly return 404 to pretend the URL doesn't exist
      send_resp(conn, 404, "Not Found")
    else
      # Get file stats (size, modified time) using UTC to comply with HTTP standards
      stat = File.stat!(filename, time: :universal)

      # Construct ETag (size + modified time hash) and Last-Modified headers
      # Note: :httpd_util belongs to the Erlang :inets application.
      # Ensure :inets is added to `extra_applications` in `mix.exs` to avoid compilation warnings and release issues.
      etag = "\"#{stat.size}-#{:erlang.phash2(stat.mtime)}\""
      last_modified = :httpd_util.rfc1123_date(stat.mtime) |> to_string()

      # Get cache validation headers from the client request
      req_etag = get_req_header(conn, "if-none-match") |> List.first()
      req_last_mod = get_req_header(conn, "if-modified-since") |> List.first()

      # If the cache matches, return 304 Not Modified directly
      if req_etag == etag or req_last_mod == last_modified do
        send_resp(conn, 304, "")
      else
        # On cache miss or initial request, read the file and return 200 with headers
        content = File.read!(filename)

        conn
        |> put_resp_header("etag", etag)
        |> put_resp_header("last-modified", last_modified)
        |> send_resp(200, content)
      end
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  # Custom plug to log IP, Method, Path, and User-Agent
  defp log_request(conn, _opts) do
    # Extract client IP (returns a tuple like {127, 0, 0, 1}, so we format it with :inet.ntoa)
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()

    # Extract User-Agent (or "-" if missing)
    ua = get_req_header(conn, "user-agent") |> List.first() || "-"

    # We use Logger instead of IO.puts because it automatically prepends the request timestamp!
    # Example output: 12:34:56.789 [info] 127.0.0.1 "GET /subscribe/..." "Clash/1.9.0"
    Logger.info("#{ip} \"#{conn.method} #{conn.request_path}\" \"#{ua}\"")

    # Important: Plugs must always return the conn!
    conn
  end
end
