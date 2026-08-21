defmodule FinancialAnalytics.Analyzer.WMA do
  @moduledoc """
  This struct is used to define the Weighted Moving Average
  analysis.
  """

  require Explorer.DataFrame

  alias __MODULE__
  alias FinancialAnalytics.Analyzer
  alias FinancialAnalytics.Analyzer.Helpers

  alias Explorer.DataFrame

  @enforce_keys [:name, :column, :window_size, :weights]
  defstruct [:name, :column, :window_size, :weights]

  @doc """
  Creates a new instance of the WMA struct.
  """
  def new(name, column, window_size, weights) do
    cond do
      length(weights) != window_size ->
        raise "The list of weights must contain the same number of elements as the window size"

      Enum.sum(weights) != 1.0 ->
        raise "The list of weights must add up to 1.0"

      true ->
        %__MODULE__{
          name: name,
          column: column,
          window_size: window_size,
          weights: weights
        }
    end
  end

  defimpl Analyzer do
    def perform(
          %WMA{name: name, column: column, window_size: window_size, weights: weights},
          %DataFrame{} = data_frame
        ) do
      Helpers.validate_new_series!(data_frame, name)

      DataFrame.mutate(data_frame, %{
        ^name =>
          cast(
            window_mean(col(^column), ^window_size, weights: ^weights, min_periods: nil),
            {:decimal, 38, 4}
          )
      })
    end
  end
end
