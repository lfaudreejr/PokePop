defmodule PokePop.Repo do
  use Ecto.Repo,
    otp_app: :poke_pop,
    adapter: Ecto.Adapters.Postgres
end
