defmodule Canopy.Rest do
  require Logger

  @default_headers [
    {~c"User-Agent", ~c"Elixir"}
  ]

  def get_json(url, headers) do
    Application.ensure_all_started([:inets, :ssl])

    Logger.debug("sending GET to: #{url}")

    :httpc.request(:get, {String.to_charlist(url), headers ++ @default_headers}, [], [])
    |> handle_json_result()
  end

  @application_json ~c"Application/Json"
  def post_json(url, headers, body) do
    Application.ensure_all_started([:inets, :ssl])

    Logger.debug("sending POST to: #{url}")

    :httpc.request(
      :post,
      {String.to_charlist(url), headers ++ @default_headers, @application_json,
       :json.encode(body)},
      [],
      []
    )
    |> handle_json_result()
  end

  defp handle_json_result(result) do
    case result do
      {:ok, {{_, 200, _}, _, body}} ->
        json = to_string(body) |> :json.decode()
        {:ok, json}

      {:ok, {{_, 201, _}, _, _body}} ->
        {:ok, nil}

      {:ok, {{_, status_code, _}, _, body}} ->
        message = "GitHub API returned status #{status_code}: #{body}."
        Logger.warning(message)
        {:error, message}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
