defmodule Incense do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Incense.Token
    ]

    opts = [strategy: :one_for_one, name: Incense.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
