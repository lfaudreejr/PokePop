defmodule PokePopWeb.Router do
  use PokePopWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :assign_client_id
    plug :fetch_live_flash
    plug :put_root_layout, html: {PokePopWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json", "sse"]
  end

  scope "/", PokePopWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/greeting", PageController, :greeting
    get "/results", PageController, :results
    post "/vote", PageController, :vote

    get "/sse", PageController, :sse
  end

  defp assign_client_id(conn, _opts) do
    case get_session(conn, :client_id) do
      nil ->
        id = Ecto.UUID.generate()

        conn
        |> put_session(:client_id, id)
        |> assign(:client_id, id)

      id ->
        assign(conn, :client_id, id)
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", PokePopWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:poke_pop, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PokePopWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
