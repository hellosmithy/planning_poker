defmodule PlanningPoker.Rooms.Decks do
  @moduledoc """
  A module that provides the decks for the Planning Poker game.
  """

  alias PlanningPoker.Rooms.Card

  @type deck_type :: :mountain_goat | :fibonacci | :sequential | :playing_cards | :t_shirt_sizes
  @type t :: {deck_type(), [Card.t()]}

  @decks %{
    mountain_goat: [
      %Card{id: "mg.1", label: "0", value: 0},
      %Card{id: "mg.2", label: "½", value: 0.5},
      %Card{id: "mg.3", label: "1", value: 1},
      %Card{id: "mg.4", label: "2", value: 2},
      %Card{id: "mg.5", label: "3", value: 3},
      %Card{id: "mg.6", label: "5", value: 5},
      %Card{id: "mg.7", label: "8", value: 8},
      %Card{id: "mg.8", label: "13", value: 1},
      %Card{id: "mg.9", label: "21", value: 21},
      %Card{id: "mg.10", label: "34", value: 34},
      %Card{id: "mg.11", label: "55", value: 55},
      %Card{id: "mg.12", label: "89", value: 89},
      %Card{id: "mg.13", label: "?", value: nil},
      %Card{id: "mg.14", label: "∞", value: nil}
    ],
    fibonacci: [
      %Card{id: "fib.1", label: "0", value: 0},
      %Card{id: "fib.2", label: "1", value: 1},
      %Card{id: "fib.3", label: "2", value: 2},
      %Card{id: "fib.4", label: "3", value: 3},
      %Card{id: "fib.5", label: "5", value: 5},
      %Card{id: "fib.6", label: "8", value: 8},
      %Card{id: "fib.7", label: "13", value: 13},
      %Card{id: "fib.8", label: "21", value: 21},
      %Card{id: "fib.9", label: "34", value: 34},
      %Card{id: "fib.10", label: "55", value: 55},
      %Card{id: "fib.11", label: "89", value: 89},
      %Card{id: "fib.12", label: "?", value: nil}
    ],
    sequential: [
      %Card{id: "seq.1", label: "0", value: 0},
      %Card{id: "seq.2", label: "1", value: 1},
      %Card{id: "seq.3", label: "2", value: 2},
      %Card{id: "seq.4", label: "3", value: 3},
      %Card{id: "seq.5", label: "4", value: 4},
      %Card{id: "seq.6", label: "5", value: 5},
      %Card{id: "seq.7", label: "6", value: 6},
      %Card{id: "seq.8", label: "7", value: 7},
      %Card{id: "seq.9", label: "8", value: 8},
      %Card{id: "seq.10", label: "9", value: 9},
      %Card{id: "seq.11", label: "10", value: 10},
      %Card{id: "seq.12", label: "?", value: nil}
    ],
    playing_cards: [
      %Card{id: "pc.1", label: "A♠", value: 1},
      %Card{id: "pc.2", label: "2♠", value: 2},
      %Card{id: "pc.3", label: "3♠", value: 3},
      %Card{id: "pc.4", label: "5♠", value: 5},
      %Card{id: "pc.5", label: "8♠", value: 8},
      %Card{id: "pc.6", label: "K♠", value: nil}
    ],
    t_shirt_sizes: [
      %Card{id: "ts.1", label: "XS", value: nil},
      %Card{id: "ts.2", label: "S", value: nil},
      %Card{id: "ts.3", label: "M", value: nil},
      %Card{id: "ts.4", label: "L", value: nil},
      %Card{id: "ts.5", label: "XL", value: nil},
      %Card{id: "ts.6", label: "?", value: nil}
    ]
  }

  @spec get_deck_types() :: [deck_type()]
  def get_deck_types() do
    @decks |> Map.keys()
  end

  @spec get_deck(deck_type()) :: t
  def get_deck(type) do
    {type, @decks[type]}
  end

  @spec get_card_by_id(t(), String.t()) :: Card.t() | nil
  def get_card_by_id({_, deck}, card_id) do
    Enum.find(deck, fn card -> card.id == card_id end)
  end
end
