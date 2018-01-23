use Mix.Config

config :incense, Incense.Token,
  key: :metadata,
  expires_in: 3600,
  mode: :lazy

config :incense, Incense.Backoff, retry_unit: 500.0

import_config "#{Mix.env()}.exs"
