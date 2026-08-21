defmodule FinancialAnalytics.Analyzer.DPO do
  @moduledoc """
  This struct is used to define the Detrended Price
  Oscillator analysis.
  """

  require Explorer.DataFrame

  alias __MODULE__
  alias FinancialAnalytics.Analyzer
  alias FinancialAnalytics.Analyzer.Helpers
  alias FinancialAnalytics.Analyzer.SMA

  alias Explorer.DataFrame

  @enforce_keys [:base_name, :cycle_period, :closing_column]
  defstruct [:base_name, :cycle_period, :closing_column]

  @doc """
  Creates a new instance of the MACD struct.
  """
  def new(base_name, cycle_period, closing_column) do
    %__MODULE__{
      base_name: base_name,
      cycle_period: cycle_period,
      closing_column: closing_column
    }
  end

  defimpl Analyzer do
    def perform(
          %DPO{base_name: base_name, cycle_period: cycle_period, closing_column: closing_column},
          %DataFrame{} = data_frame
        ) do
      cycle_sma_name = "#{base_name}_sma_#{cycle_period}"
      sma_detrender_name = "#{base_name}_sma_detrender"

      Helpers.validate_new_series!(data_frame, base_name)
      Helpers.validate_new_series!(data_frame, cycle_sma_name)
      Helpers.validate_new_series!(data_frame, sma_detrender_name)

      detrender_shift =
        cycle_period
        |> Decimal.div(2)
        |> Decimal.add(1)
        |> Decimal.round(0)
        |> Decimal.to_integer()

      data_frame
      |> Helpers.perform_one(SMA.new(cycle_sma_name, closing_column, cycle_period))
      |> DataFrame.mutate(%{
        ^sma_detrender_name => shift(col(^cycle_sma_name), ^detrender_shift)
      })
      |> DataFrame.mutate(%{
        ^base_name => subtract(col(^closing_column), col(^sma_detrender_name))
      })
    end
  end
end
