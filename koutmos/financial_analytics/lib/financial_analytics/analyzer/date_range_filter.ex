defmodule FinancialAnalytics.Analyzer.DateRangeFilter do
  @moduledoc """
  This struct is used to define the date range filter for
  a dataframe.
  """

  require Explorer.DataFrame

  alias __MODULE__
  alias FinancialAnalytics.Analyzer

  alias Explorer.DataFrame

  @enforce_keys [:column, :start_date, :end_date]
  defstruct [:column, :start_date, :end_date]

  @doc """
  Creates a new instance of the DateRangeFilter struct.
  """
  def new(column, start_date, end_date) do
    %__MODULE__{
      column: column,
      start_date: start_date,
      end_date: end_date
    }
  end

  defimpl Analyzer do
    def perform(
          %DateRangeFilter{column: column, start_date: start_date, end_date: end_date},
          %DataFrame{} = data_frame
        ) do
      data_frame
      |> DataFrame.filter(greater_equal(col(^column), ^start_date))
      |> DataFrame.filter(less_equal(col(^column), ^end_date))
    end
  end
end
