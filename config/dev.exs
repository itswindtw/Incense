use Mix.Config

config :incense, Incense.Token, key: {:json, Path.expand("test-credentials.json", __DIR__)}
