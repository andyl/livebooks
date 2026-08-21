defmodule FinancialAnalytics.Analyzer.EMA do
  @moduledoc """
  This struct is used to define the Exponential Moving Average
  analysis.
  """

  require Explorer.DataFrame

  alias __MODULE__
  alias FinancialAnalytics.Analyzer
  alias FinancialAnalytics.Analyzer.Helpers

  alias Explorer.DataFrame

  @enforce_keys [:name, :column, :window_size, :smoothing_factor, :seed]
  defstruct [:name, :column, :window_size, :smoothing_factor, :seed]

  @doc """
  Creates a new instance of the EMA struct.
  """
  def new(name, column, window_size, smoothing_factor, seed) do
    %__MODULE__{
      name: name,
      column: column,
      window_size: window_size,
      smoothing_factor: smoothing_factor,
      seed: seed
    }
  end

  defimpl Analyzer do
    alias Explorer.Series

    def perform(
          %EMA{
            name: name,
            column: column,
            window_size: window_size,
            smoothing_factor: smoothing_factor,
            seed: seed
          },
          %DataFrame{} = data_frame
        ) do
      Helpers.validate_new_series!(data_frame, name)

      computed_ema_series =
        data_frame
        |> DataFrame.pull(column)
        |> Series.to_list()
        |> Enum.reduce([], fn
          price, [] ->
            ema =
              compute_ema(
                smoothing_factor,
                window_size,
                price,
                seed
              )

            [ema]

          price, [previous_ema_price | _rest] = acc ->
            ema =
              compute_ema(
                smoothing_factor,
                window_size,
                price,
                previous_ema_price
              )

            [ema | acc]
        end)
        |> Enum.reverse()
        |> Series.from_list()

      DataFrame.put(data_frame, name, computed_ema_series)
    end

    defp compute_ema(smooth_factor, window_size, current_price, previous_ema) do
      smooth_factor
      |> Decimal.div(Decimal.new(window_size + 1))
      |> Decimal.mult(Decimal.sub(current_price, previous_ema))
      |> Decimal.add(previous_ema)
      |> Decimal.round(4)
    end
  end
end
