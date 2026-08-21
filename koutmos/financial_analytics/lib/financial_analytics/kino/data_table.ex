defmodule FinancialAnalytics.Kino.DataTable do
  @moduledoc """
  This module is used to create Kino.DataTable instances
  so that timeseries data can be displayed in a tabular
  fashion in notebooks.
  """

  alias Explorer.DataFrame

  @doc """
  This function will create a new `Kino.DataTable`
  component in Livebook given an `Explorer.DataFrame`
  and a list of columns that should be present in the
  `Kino.DataTable`. The table's column order will be the
  same as the `columns` argument that is provided.
  """
  def new(%DataFrame{} = data_frame, columns) do
    column_index =
      columns
      |> Enum.with_index()
      |> Map.new()

    data_frame
    |> DataFrame.select(columns)
    |> DataFrame.to_rows()
    |> Enum.map(fn row ->
      Enum.sort_by(row, fn {column, _value} ->
        Map.fetch!(column_index, column)
      end)
    end)
    |> Kino.DataTable.new(sorting_enabled: false)
  end
end
