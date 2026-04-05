defmodule Subconverter.Router do
  use Plug.Router

  # Log every incoming HTTP request for observability
  plug Subconverter.Plugs.RequestLogger
  plug :match
  plug :dispatch

  get "/subscribe/:user_id/:token" do
    Subconverter.Handlers.Subscription.call(conn, user_id, token)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
