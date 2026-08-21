defmodule FinancialAnalytics.Analyzer.Helpers do
  @moduledoc """
  This function provides small helpers to make it easier
  to work with structs implementing the `Analyzer`
  protocol.
  """

  alias Explorer.DataFrame

  alias FinancialAnalytics.Analyzer

  @doc """
  A thing wrapper around the `perform/2` protocol to make it easier to pipe
  chain data frame analyses.
  """
  def perform_one(%DataFrame{} = data_frame, analysis) do
    Analyzer.perform(analysis, data_frame)
  end

  @doc """
  A thing wrapper around the `perform/2` protocol to make it easier to
  perform multiple analyses.
  """
  def perform_many(%DataFrame{} = data_frame, analyses) do
    Enum.reduce(analyses, data_frame, fn analysis, acc ->
      Analyzer.perform(analysis, acc)
    end)
  end

  @doc """
  Checks to see if a series name already exists in a data frame.
  Raises if it is already present.
  """
  def validate_new_series!(%DataFrame{} = data_frame, analysis_name) do
    if analysis_name in DataFrame.names(data_frame) do
      raise "The provided DataFrame already has a series with the name #{analysis_name}"
    end

    :ok
  end

  @doc """
  This function is used to rename DataFrame columns returned from YFinance into
  normalized names that we can use throughout the rest of the analysis framework.
  """
  def normalize_yfinance_dataframe(%DataFrame{} = data_frame, symbol) do
    symbol = String.downcase(symbol)

    Explorer.DataFrame.rename_with(
      data_frame,
      fn column ->
        String.starts_with?(column, symbol)
      end,
      fn column ->
        String.trim_leading(column, "#{symbol}_")
      end
    )
  end
end
