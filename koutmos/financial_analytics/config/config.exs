import Config

config :fred,
  api_key: System.fetch_env!("LB_FRED_API_KEY")
