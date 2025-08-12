alias PokePop.Pokemon

defmodule PokePop.Seeder do
  @graphql_url "https://graphql.pokeapi.co/v1beta2"
  @query """
  query GetAllPokemon {
   pokemon(where:  {
      id:  {
         _lte: 1025
      }
   }) {
     id
     name
   }
  }
  """

  def run do
    Application.ensure_all_started(:poke_pop)

    IO.puts("Clearing existing Pokemon...")
    PokePop.Repo.delete_all(Pokemon)

    IO.puts("Fetching Pokemon data...")

    case fetch_all_pokemon() do
      {:ok, pokemon_list} ->
        IO.puts("Inserting #{length(pokemon_list)} Pokemon...")

        Enum.each(pokemon_list, fn pokemon ->
          %Pokemon{}
          |> Pokemon.changeset(%{
            name: pokemon.name,
            dex_id: pokemon.id,
            up_votes: 0,
            down_votes: 0
          })
          |> PokePop.Repo.insert!(on_conflict: :nothing)

          IO.puts("Inserted Pokemon: #{pokemon.name}")
        end)

        IO.puts("Seeding completed successfully!")

      {:error, error} ->
        IO.puts("Error during seeding: #{inspect(error)}")
    end
  end

  defp fetch_all_pokemon do
    headers = [{"Content-Type", "application/json"}]
    body = Jason.encode!(%{query: @query})

    case HTTPoison.post(@graphql_url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"data" => data}} ->
            {:ok,
             data["pokemon"]
             |> Enum.map(fn pokemon ->
               %{
                 id: Integer.to_string(pokemon["id"]),
                 name: pokemon["name"]
               }
             end)}

          {:error, error} ->
            {:error, "Failed to decode JSON: #{inspect(error)}"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Request failed with status code: #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end
end

Application.ensure_all_started(:poke_pop)
