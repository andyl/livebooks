defmodule FinancialAnalytics.Analyzer.MACD do
  @moduledoc """
  This struct is used to define the Moving Average Convergence
  Divergence analysis.
  """

  require Explorer.DataFrame

  alias __MODULE__
  alias FinancialAnalytics.Analyzer
  alias FinancialAnalytics.Analyzer.Helpers

  alias Explorer.DataFrame

  @enforce_keys [:base_name, :ema_1, :ema_2, :window_size]
  defstruct [:base_name, :ema_1, :ema_2, :window_size]

  @doc """
  Creates a new instance of the MACD struct.
  """
  def new(base_name, ema_1, ema_2, window_size) do
    %__MODULE__{
      base_name: base_name,
      ema_1: ema_1,
      ema_2: ema_2,
      window_size: window_size
    }
  end

  defimpl Analyzer do
    def perform(
          %MACD{base_name: base_name, ema_1: ema_1, ema_2: ema_2, window_size: window_size},
          %DataFrame{} = data_frame
        ) do
      signal_name = "#{base_name}_signal"
      histogram_name = "#{base_name}_histogram"

      Helpers.validate_new_series!(data_frame, base_name)
      Helpers.validate_new_series!(data_frame, signal_name)
      Helpers.validate_new_series!(data_frame, histogram_name)

      data_frame
      |> DataFrame.mutate(%{
        ^base_name => subtract(col(^ema_1), col(^ema_2))
      })
      |> DataFrame.mutate(%{
        ^signal_name =>
          cast(
            window_mean(col(^base_name), ^window_size, min_periods: nil),
            {:decimal, 38, 4}
          )
      })
      |> DataFrame.mutate(%{
        ^histogram_name => subtract(col(^base_name), col(^signal_name))
      })
    end
  end
end
