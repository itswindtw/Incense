defmodule Incense.BackoffTest do
  use ExUnit.Case, async: true

  use Incense.Backoff
  alias Incense.Backoff

  test "success at first time" do
    assert Backoff.retry(do: :ok) == :ok
  end

  test "success in third attempt" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    assert (Backoff.retry do
              x = Agent.get_and_update(agent, fn x -> {x, x + 1} end)
              if x < 2, do: :error, else: :ok
            end) == :ok
  end

  test "fail after 3 attempts" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    assert (Backoff.retry do
              x = Agent.get_and_update(agent, fn x -> {x, x + 1} end)
              if x < 3, do: {:error, :oh_my_god}, else: :ok
            end) == {:error, :oh_my_god}
  end

  test "catch exception" do
    assert_raise RuntimeError, fn ->
      Backoff.retry do
        raise "Oh no!"
        :ok
      end
    end
  end
end
