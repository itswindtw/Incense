# Incense

Burn an incense. Let it carry your data to cloud.

Incense is here for managing your Google Cloud data.
It was created in 2016 since there wasn't an official API client library for Cloud Storage.

## Installation

1. Add incense to your list of dependencies in mix.exs:

```elixir
def deps do
  [{:incense, "~> 0.2.0"}]
end
```

2. Configure incense with your project name and JSON credentials (you can skip credentials if your application is running on GCE):

```elixir
config :incense,
  project_name: 'hola'
  key: {:json, "path/to/your/google/credentials.json"}
```

3. Ensure incense is started before your application (no required for recent versions of Elixir):

```elixir
def application do
  [applications: [:incense]]
end
```

