defmodule FinancialAnalytics.VegaLite.DataFrameTransform do
  @moduledoc """
  This module provides utilities for you to massage and transform
  data within a DataFrame into a format that you can easily
  use inside of VegaLite.
  """

  alias Explorer.DataFrame

  defmodule DatasetDefinition do
    defstruct [:key, :date_column, :zip_columns, :series_name, :filter]
  end

  def convert(%DataFrame{} = data_frame, dataset_definitions) do
    Enum.map(dataset_definitions, fn %DatasetDefinition{} = dataset_definition ->
      series_namer =
        case dataset_definition do
          %DatasetDefinition{series_name: nil} ->
            fn zip_column, _ ->
              zip_column
            end

          %DatasetDefinition{series_name: series_name} when is_binary(series_name) ->
            fn _, _ ->
              series_name
            end

          %DatasetDefinition{series_name: series_name_function}
          when is_function(series_name_function, 2) ->
            series_name_function
        end

      formatted_data =
        Enum.flat_map(dataset_definition.zip_columns, fn zip_column ->
          extract_columns = [dataset_definition.date_column, zip_column]

          data_frame
          |> filter_data_frame(dataset_definition)
          |> DataFrame.select(extract_columns)
          |> DataFrame.rename(%{zip_column => "value"})
          |> DataFrame.to_rows()
          |> Enum.map(fn row ->
            Map.put(row, "series", series_namer.(zip_column, row))
          end)
        end)

      {dataset_definition.key, formatted_data}
    end)
  end

  defp filter_data_frame(%DataFrame{} = data_frame, %DatasetDefinition{filter: nil}) do
    data_frame
  end

  defp filter_data_frame(%DataFrame{} = data_frame, %DatasetDefinition{filter: filter_function}) do
    filter_function.(data_frame)
  end
end
