defmodule FinancialAnalytics.MixProject do
  use Mix.Project

  def project do
    [
      app: :financial_analytics,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {FinancialAnalytics.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:yfinance, "~> 0.3.0"},
      {:fred, "~> 0.0.1"},
      {:vega_lite, "~> 0.1"},
      {:kino, "~> 0.17"},
      {:kino_vega_lite, "~> 0.1"},
      {:decimal, "~> 2.3"},
      {:explorer, "~> 0.11"},
      {:table, "~> 0.1"}
    ]
  end
end
