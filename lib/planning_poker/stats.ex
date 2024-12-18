defmodule PlanningPoker.Stats do
  @spec mean([number]) :: number | nil
  def mean([]), do: nil

  def mean(values) do
    Enum.sum(values) / Enum.count(values)
  end

  @spec stdev([number]) :: number | nil
  def stdev([]), do: nil

  def stdev(numbers) do
    numbers
    |> variance()
    |> :math.sqrt()
  end

  @spec variance([number]) :: number | nil
  def variance([]), do: nil

  def variance(numbers) do
    list_mean = mean(numbers)
    numbers |> Enum.map(fn x -> (list_mean - x) * (list_mean - x) end) |> mean
  end
end
