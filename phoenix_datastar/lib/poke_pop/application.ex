defmodule PokePop.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PokePopWeb.Telemetry,
      PokePop.Repo,
      {DNSCluster, query: Application.get_env(:poke_pop, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PokePop.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PokePop.Finch},
      # Start a worker by calling: PokePop.Worker.start_link(arg)
      # {PokePop.Worker, arg},
      # Start to serve requests, typically the last entry
      PokePopWeb.Endpoint,
      {Cachex, [:pokemon_cache]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PokePop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PokePopWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
