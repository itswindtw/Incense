defmodule Incense.TokenTest do
  use ExUnit.Case, async: true

  alias Incense.Token

  test "handle_call with an active token" do
    active_token = "12345678890"
    state = %{tokens: %{hola: active_token}}

    {:reply, {:ok, token}, _} = Token.handle_call({:get, :hola}, nil, state)
    assert token == active_token
  end

  test "handle_info with a lazy strategy" do
    state = %{tokens: %{whatever: "whatever_token"}}
    {:noreply, new_state} = Token.handle_info({:token_timeout, :whatever}, state)

    assert Map.fetch(new_state.tokens, :whatever) == :error
  end

  @tag :external
  test "it fetchs an active token" do
    assert {:ok, token} = Token.get("https://www.googleapis.com/auth/cloud-platform")
    assert token != nil
    assert {:ok, ^token} = Token.get("https://www.googleapis.com/auth/cloud-platform")
  end

  @tag :external
  test "it fetchs tokens from different scope" do
    assert {:ok, token_profile} = Token.get("profile")
    assert token_profile != nil
    assert {:ok, token_email} = Token.get("email")
    assert token_email != nil

    assert token_profile != token_email
  end
end
