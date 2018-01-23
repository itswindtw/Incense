defmodule Incense.Token do
  @moduledoc false

  use GenServer

  @config Application.get_env(:incense, Incense.Token)

  ## Client APIs

  def start_link(_) do
    GenServer.start_link(__MODULE__, @config[:key], name: __MODULE__)
  end

  def get(scope) do
    GenServer.call(__MODULE__, {:get, scope})
  end

  ## Callbacks

  def init(:metadata) do
    {:ok,
     %{
       type: :metadata,
       tokens: %{}
     }}
  end

  def init({:json, path}) do
    json = path |> File.read!() |> Poison.decode!()

    {:ok,
     %{
       type: :jwt,
       client_email: json["client_email"],
       signing_key: decode_key(json["private_key"]),
       tokens: %{}
     }}
  end

  def handle_call({:get, scope}, _from, %{tokens: tokens} = state) do
    case Map.fetch(tokens, scope) do
      {:ok, token} ->
        {:reply, {:ok, token}, state}

      :error ->
        {token, state} = refresh(state, scope)
        {:reply, {:ok, token}, state}
    end
  end

  def handle_info({:token_timeout, scope}, state) do
    state =
      case @config[:mode] do
        :lazy ->
          %{state | tokens: Map.delete(state.tokens, scope)}

        :eager ->
          {_, state} = refresh(state, scope)
          state
      end

    {:noreply, state}
  end

  ## refresh the token

  defp refresh(state, scope) do
    {token, expires_in} = fetch_token(state, scope)

    expires_in = if expires_in < 30, do: 0, else: expires_in - 30
    Process.send_after(self(), {:token_timeout, scope}, :timer.seconds(expires_in))

    {token, %{state | tokens: Map.put(state.tokens, scope, token)}}
  end

  defp fetch_token(%{type: :jwt} = state, scope) do
    unix_time = :os.system_time(:seconds)
    jwt = make_jwt(scope, unix_time, state.client_email, state.signing_key)
    %{"access_token" => token, "expires_in" => expires_in} = fetch_access_token(jwt)

    {token, expires_in}
  end

  defp fetch_token(%{type: :metadata}, _scope) do
    %{"access_token" => token, "expires_in" => expires_in} =
      HTTPoison.get!(
        "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token",
        [{"Metadata-Flavor", "Google"}]
      ).body
      |> Poison.decode!()

    {token, expires_in}
  end

  ## RSA utils

  defp decode_key(text) do
    text
    |> :public_key.pem_decode()
    |> List.first()
    |> :public_key.pem_entry_decode()
    |> asn1_decode
  end

  defp asn1_decode({:PrivateKeyInfo, _, _, der_key, _}) do
    :public_key.der_decode(:RSAPrivateKey, der_key)
  end

  defp asn1_decode(der), do: der

  ## JWT utils

  defp make_jwt(scope, unix_time, client_email, signing_key) do
    encoded_header = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9"

    claim = %{
      "iss" => client_email,
      "scope" => scope,
      "aud" => "https://www.googleapis.com/oauth2/v4/token",
      "iat" => unix_time,
      "exp" => unix_time + @config[:expires_in]
    }

    encoded_claim = claim |> Poison.encode!() |> Base.url_encode64()

    raw_sig = "#{encoded_header}.#{encoded_claim}"
    computed_sig = :public_key.sign(raw_sig, :sha256, signing_key)
    encoded_sig = Base.url_encode64(computed_sig)

    "#{encoded_header}.#{encoded_claim}.#{encoded_sig}"
  end

  defp fetch_access_token(jwt) do
    resp =
      HTTPoison.post!(
        "https://www.googleapis.com/oauth2/v4/token",
        {:form, [grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: jwt]}
      )

    %HTTPoison.Response{status_code: 200, body: body} = resp
    Poison.decode!(body)
  end
end
