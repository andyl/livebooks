defmodule FinancialAnalytics.Analyzer.SMA do
  @moduledoc """
  This struct is used to define the Simple Moving Average
  analysis.
  """

  require Explorer.DataFrame

  alias __MODULE__
  alias FinancialAnalytics.Analyzer
  alias FinancialAnalytics.Analyzer.Helpers

  alias Explorer.DataFrame

  @enforce_keys [:name, :column, :window_size]
  defstruct [:name, :column, :window_size]

  @doc """
  Creates a new instance of the SMA struct.
  """
  def new(name, column, window_size) do
    %__MODULE__{
      name: name,
      column: column,
      window_size: window_size
    }
  end

  defimpl Analyzer do
    def perform(
          %SMA{name: name, column: column, window_size: window_size},
          %DataFrame{} = data_frame
        ) do
      Helpers.validate_new_series!(data_frame, name)

      DataFrame.mutate(data_frame, %{
        ^name =>
          cast(
            window_mean(col(^column), ^window_size, min_periods: nil),
            {:decimal, 38, 4}
          )
      })
    end
  end
end
