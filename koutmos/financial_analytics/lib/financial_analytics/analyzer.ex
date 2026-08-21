defprotocol FinancialAnalytics.Analyzer do
  @moduledoc """
  This protocol is used by all of the techniques so that
  we can consistently mutate DataFrames and add columns
  for each of our analysis techniques.
  """

  alias Explorer.DataFrame

  @type t :: Billable.t()

  @doc """
  The function that protocol implementations need to provide.
  """
  @spec perform(analysis :: t(), data_frame :: DataFrame.t()) :: DataFrame.t()
  def perform(analysis, data_frame)
end
