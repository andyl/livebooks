defmodule FinancialAnalytics.Analyzer.STOCH do
  @moduledoc """
  This struct is used to define the Stochasic oscillator
  analysis.
  """

  require Explorer.DataFrame

  alias __MODULE__
  alias FinancialAnalytics.Analyzer
  alias FinancialAnalytics.Analyzer.Helpers
  alias FinancialAnalytics.Analyzer.SMA

  alias Explorer.DataFrame

  @enforce_keys [
    :base_name,
    :high_column,
    :low_column,
    :close_column,
    :window_size,
    :smoothing_factor
  ]

  defstruct [
    :base_name,
    :high_column,
    :low_column,
    :close_column,
    :window_size,
    :smoothing_factor
  ]

  @doc """
  Creates a new instance of the MACD struct.
  """
  def new(base_name, high_column, low_column, close_column, window_size, smoothing_factor) do
    %STOCH{
      base_name: base_name,
      high_column: high_column,
      low_column: low_column,
      close_column: close_column,
      window_size: window_size,
      smoothing_factor: smoothing_factor
    }
  end

  defimpl Analyzer do
    def perform(
          %STOCH{
            base_name: base_name,
            high_column: high_column,
            low_column: low_column,
            close_column: close_column,
            window_size: window_size,
            smoothing_factor: smoothing_factor
          },
          %DataFrame{} = data_frame
        ) do
      k_name = "#{base_name}_k"
      d_name = "#{base_name}_d"

      Helpers.validate_new_series!(data_frame, k_name)
      Helpers.validate_new_series!(data_frame, d_name)

      data_frame
      |> DataFrame.mutate(%{
        ^k_name =>
          cast(
            divide(
              subtract(
                window_min(cast(col(^low_column), :f64), ^window_size, min_periods: nil),
                col(^close_column)
              ),
              subtract(
                window_min(cast(col(^low_column), :f64), ^window_size, min_periods: nil),
                window_max(cast(col(^high_column), :f64), ^window_size, min_periods: nil)
              )
            ),
            {:decimal, 38, 4}
          )
      })
      |> Helpers.perform_one(SMA.new(d_name, k_name, smoothing_factor))
    end
  end
end
