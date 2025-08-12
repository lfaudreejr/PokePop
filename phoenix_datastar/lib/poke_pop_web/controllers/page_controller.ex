defmodule PokePopWeb.PageController do
  import Ecto.Query
  require Logger
  use PokePopWeb, :controller
  use Phoenix.Component
  alias PokePop.Pokemon
  alias PokePop.Repo

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout

    IO.inspect(self(), label: "Home self")

    [first_entry, second_entry] = get_random_pair()
    IO.inspect(first_entry, label: "first _entry")
    IO.inspect(second_entry, label: "second _entry")

    token = get_csrf_token()

    render(conn, :home, first_entry: first_entry, second_entry: second_entry, csrf_token: token)
  end

  def greeting(conn, _params) do
    IO.inspect(self(), label: "Greeting self")

    html =
      PokePopWeb.PokeComponents.greeting(%{})
      |> Phoenix.HTML.Safe.to_iodata()
      |> IO.iodata_to_binary()

    client_id = get_session(conn, :client_id)
    IO.inspect(client_id)
    topic = "client:" <> client_id

    Phoenix.PubSub.broadcast(PokePop.PubSub, topic, {:patch_elements, %{html: html, opts: []}})

    resp(conn, 200, "OK")
  end

  def vote(conn, _params) do
    case DataStarSSE.ServerSentEventGenerator.read_signals(conn) do
      {:ok, conn, signals} ->
        IO.inspect(signals, label: "signals")
        winner_id = signals["winner"]
        loser_id = signals["loser"]
        IO.inspect(winner_id, label: "winner")
        IO.inspect(loser_id, label: "loser")

        winner = get_pokemon_by_id(winner_id)
        IO.inspect(winner, label: "got winner")
        loser = get_pokemon_by_id(loser_id)
        IO.inspect(loser, label: "got loser")

        Repo.transact(fn ->
          with {:ok, winner} <-
                 winner
                 |> Pokemon.changeset(%{up_votes: winner.up_votes + 1})
                 |> Repo.update(),
               {:ok, loser} <-
                 loser
                 |> Pokemon.changeset(%{down_votes: loser.down_votes + 1})
                 |> Repo.update() do
            {:ok, [winner, loser]}
          else
            {:error, _} -> Repo.rollback(:error)
          end
        end)

        [first_entry, second_entry] = get_random_pair()
        IO.inspect(first_entry, label: "first_entry")
        IO.inspect(second_entry, label: "second_entry")

        token = get_csrf_token()

        html =
          PokePopWeb.PokeComponents.poke_vote(%{
            first_entry: first_entry,
            second_entry: second_entry,
            csrf_token: token
          })
          |> Phoenix.HTML.Safe.to_iodata()
          |> IO.iodata_to_binary()

        client_id = get_session(conn, :client_id)
        IO.inspect(client_id)
        topic = "client:" <> client_id

        Phoenix.PubSub.broadcast(
          PokePop.PubSub,
          topic,
          {:patch_elements, %{html: html, opts: []}}
        )

        resp(conn, 200, "OK")

      {:error, error} ->
        IO.puts(:std_error, error)
        resp(conn, 500, "Voting Error")
    end
  end

  def results(conn, _params) do
    pokemon = get_pokemon_by_win_rate()

    render(conn, :results, %{pokemon: pokemon})
  end

  def sse(conn, _params) do
    client_id = get_session(conn, :client_id)
    IO.inspect(client_id)
    topic = "client:" <> client_id
    Phoenix.PubSub.subscribe(PokePop.PubSub, topic)

    conn
    |> DataStarSSE.ServerSentEventGenerator.new_sse()
    |> listen_for_datastar_events()
  end

  defp listen_for_datastar_events(conn) do
    receive do
      {:patch_elements, payload} ->
        DataStarSSE.ServerSentEventGenerator.patch_elements(conn, payload.html, payload.opts)
        |> listen_for_datastar_events()

      {:patch_signals, payload} ->
        DataStarSSE.ServerSentEventGenerator.patch_signals(conn, payload.signals, payload.opts)
        |> listen_for_datastar_events()

      {:execute_script, payload} ->
        DataStarSSE.ServerSentEventGenerator.execute_script(conn, payload.script, payload.opts)
        |> listen_for_datastar_events()

      _ ->
        listen_for_datastar_events(conn)
    after
      5_000 ->
        # Send a periodic ping if no messages in 30s
        case chunk(conn, ": ping\n\n") do
          {:ok, conn} -> listen_for_datastar_events(conn)
          {:error, :closed} -> conn
          {:error, :enotconn} -> conn
        end
    end
  end

  defp get_pokemon_by_id(id) do
    Repo.get(Pokemon, id)
  end

  defp get_random_pair do
    query =
      from(e in Pokemon,
        order_by: fragment("RANDOM()"),
        limit: 2
      )

    Repo.all(query)
  end

  defp get_pokemon_by_win_rate do
    base_query =
      from p in Pokemon,
        where: p.up_votes > 0 or p.down_votes > 0,
        select: %{
          name: p.name,
          dex_id: p.dex_id,
          up_votes: p.up_votes,
          down_votes: p.down_votes
        }

    base_query
    |> Repo.all()
    |> Enum.map(fn pokemon ->
      total_votes = pokemon.up_votes + pokemon.down_votes
      win_percentage = calculate_percentage(pokemon.up_votes, total_votes)
      loss_percentage = calculate_percentage(pokemon.down_votes, total_votes)

      pokemon
      |> Map.put(:total_votes, total_votes)
      |> Map.put(:win_percentage, win_percentage)
      |> Map.put(:loss_percentage, loss_percentage)
    end)
    |> Enum.sort_by(
      fn pokemon ->
        {pokemon.win_percentage, pokemon.up_votes}
      end,
      :desc
    )
  end

  defp calculate_percentage(part, total) when total > 0 do
    percentage = part / total * 100
    Float.round(percentage, 2)
  end

  defp calculate_percentage(_, _), do: 0.0
end
