defmodule FinancialAnalytics.Analyzer.EntryExit do
  @moduledoc """
  This struct is used to define the Exponential Moving Average
  analysis.
  """

  require Explorer.DataFrame

  alias __MODULE__
  alias FinancialAnalytics.Analyzer
  alias FinancialAnalytics.Analyzer.Helpers

  alias Explorer.DataFrame

  @enforce_keys [:name, :primary_signal_column, :trailing_signal_columns]
  defstruct [:name, :primary_signal_column, :trailing_signal_columns]

  @doc """
  Creates a new instance of the EntryExit struct.
  """
  def new(name, primary_signal_column, trailing_signal_columns) do
    %__MODULE__{
      name: name,
      primary_signal_column: primary_signal_column,
      trailing_signal_columns: trailing_signal_columns
    }
  end

  defimpl Analyzer do
    alias Explorer.Series

    def perform(
          %EntryExit{
            name: name,
            primary_signal_column: primary_signal_column,
            trailing_signal_columns: trailing_signal_columns
          },
          %DataFrame{} = data_frame
        ) do
      Helpers.validate_new_series!(data_frame, name)

      primary_signal_list =
        data_frame
        |> DataFrame.pull(primary_signal_column)
        |> Series.to_list()

      trailing_signals_lists =
        Enum.map(trailing_signal_columns, fn trailing_signal_column ->
          data_frame
          |> DataFrame.pull(trailing_signal_column)
          |> Series.to_list()
        end)

      initial_state = %{actions: [], current_action: nil}

      computed_entry_exit_series =
        [primary_signal_list | trailing_signals_lists]
        |> Enum.zip_reduce(initial_state, fn [primary_signal | trailing_signals], acc ->
          cond do
            # Make sure none of the data is nil
            Enum.any?([primary_signal | trailing_signals], &is_nil(&1)) ->
              prepend_actions(acc, 0)

            # If the primary signal crosses over in the positive direction relative
            # to the trailing signals.
            all_trailing_signals?(primary_signal, trailing_signals, :gt) ->
              if acc.current_action == :buy do
                prepend_actions(acc, 0)
              else
                acc
                |> Map.put(:current_action, :buy)
                |> prepend_actions(1)
              end

            # If the primary signal crosses over in the negative direction relative
            # to the trailing signals.
            all_trailing_signals?(primary_signal, trailing_signals, :lt) ->
              if acc.current_action == :sell do
                prepend_actions(acc, 0)
              else
                acc
                |> Map.put(:current_action, :sell)
                |> prepend_actions(-1)
              end

            true ->
              Map.update!(acc, :actions, fn previous_actions ->
                [0 | previous_actions]
              end)
          end
        end)
        |> Map.fetch!(:actions)
        |> Enum.reverse()
        |> Series.from_list()

      DataFrame.put(data_frame, name, computed_entry_exit_series)
    end

    defp prepend_actions(acc, value) do
      acc
      |> Map.update!(:actions, fn previous_actions ->
        [value | previous_actions]
      end)
    end

    defp all_trailing_signals?(primary_signal, trailing_signals, less_than_or_greater_than) do
      Enum.all?(trailing_signals, fn trailing_signal ->
        Decimal.compare(primary_signal, trailing_signal) == less_than_or_greater_than
      end)
    end
  end
end
