defmodule PokePop.Repo.Migrations.CreatePokemon do
  use Ecto.Migration

  def change do
    create table(:pokemon) do
      add :name, :string
      add :dex_id, :string
      add :up_votes, :integer
      add :down_votes, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
