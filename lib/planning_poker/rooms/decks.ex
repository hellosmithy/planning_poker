defmodule PlanningPoker.Rooms.Decks do
  @moduledoc """
  A module that provides the decks for the Planning Poker game.
  """

  @type t :: {atom(), [{String.t(), integer() | nil}]}

  @decks %{
    mountain_goat: [
      {"0", 0},
      {"½", 0.5},
      {"1", 1},
      {"2", 2},
      {"3", 3},
      {"5", 5},
      {"8", 8},
      {"13", 13},
      {"20", 20},
      {"40", 40},
      {"100", 100},
      {"?", nil},
      {"∞", nil}
    ],
    fibonacci: [
      {"0", 0},
      {"1", 1},
      {"2", 2},
      {"3", 3},
      {"5", 5},
      {"8", 8},
      {"13", 13},
      {"21", 21},
      {"34", 34},
      {"55", 55},
      {"89", 89},
      {"?", nil}
    ],
    sequential: [
      {"0", 0},
      {"1", 1},
      {"2", 2},
      {"3", 3},
      {"4", 4},
      {"5", 5},
      {"6", 6},
      {"7", 7},
      {"8", 8},
      {"9", 9},
      {"10", 10},
      {"?", nil}
    ],
    playing_cards: [
      {"A♠", 1},
      {"2♠", 2},
      {"3♠", 3},
      {"5♠", 5},
      {"8♠", 8},
      {"K♠", nil}
    ],
    t_shirt_sizes: [
      {"XS", nil},
      {"S", nil},
      {"M", nil},
      {"L", nil},
      {"XL", nil},
      {"?", nil}
    ]
  }

  @spec get_deck_types() :: [atom()]
  def get_deck_types() do
    @decks |> Map.keys()
  end

  @spec get_deck(atom()) :: t
  def get_deck(type) do
    {type, @decks[type]}
  end
end
