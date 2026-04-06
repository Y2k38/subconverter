defmodule Subconverter.Router do
  use Plug.Router

  # Log every incoming HTTP request for observability
  plug Subconverter.Plugs.RequestLogger
  plug :match
  plug :dispatch

  forward "/subscribe", to: Subconverter.Handlers.Subscription

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
