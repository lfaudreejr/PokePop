defmodule PokePopWeb.PokeComponents do
  use Phoenix.Component

  def greeting(assigns) do
    ~H"""
    <h1 id="greeting">Hello World!</h1>
    """
  end

  def poke_vote(assigns) do
    ~H"""
    <div id="poke-vote" class="w-full grow flex flex-col items-center justify-center gap-8">
      <div class="md:grid grid-cols-2 gap-8" data-signals="{winner: '', loser: ''}">
        <div class="flex flex-col gap-4">
          <img
            src={"https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/#{@first_entry.dex_id}.png"}
            alt={"#{@first_entry.name}"}
            class="w-48 h-48"
            style="image-rendering: pixelated;"
          />
          <div class="text-center">
            <span class="text-gray-500 text-lg">#{@first_entry.dex_id}</span>
            <h2 class="text-2xl font-bold capitalize">{@first_entry.name}</h2>
          </div>
          <button
            class="hover:bg-gray-700 bg-blue-600 text-white px-4 py-2 rounded-md"
            data-on-click={"
            $winner = #{@first_entry.dex_id};
            $loser = #{@second_entry.dex_id};
            @post('/vote', {headers: {'X-Csrf-Token': '#{@csrf_token}'}});"}
          >
            Vote
          </button>
        </div>

        <div class="flex flex-col gap-4">
          <img
            src={"https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/#{@second_entry.dex_id}.png"}
            alt={"#{@second_entry.name}"}
            class="w-48 h-48"
            style="image-rendering: pixelated;"
          />
          <div class="text-center">
            <span class="text-gray-500 text-lg">#{@second_entry.dex_id}</span>
            <h2 class="text-2xl font-bold capitalize">{@second_entry.name}</h2>
          </div>
          <button
            class="hover:bg-gray-700 bg-blue-600 text-white px-4 py-2 rounded-md"
            data-on-click={
              "$winner = #{@second_entry.dex_id};
              $loser = #{@first_entry.dex_id};
              @post('/vote', {headers: {'X-Csrf-Token': '#{@csrf_token}'}});"}
          >
            Vote
          </button>
        </div>
      </div>
    </div>
    """
  end
end
