defmodule Canopy.Rest do
  def get_json(url, headers) do
    Application.ensure_all_started([:inets, :ssl])

    :httpc.request(:get, {String.to_charlist(url), headers}, [], []) |> handle_json_result()
  end

  @application_json String.to_charlist("Application/Json")
  def post_json(url, headers, body) do
    Application.ensure_all_started([:inets, :ssl])

    :httpc.request(
      :post,
      {String.to_charlist(url), headers, @application_json, :json.encode(body)},
      [],
      []
    )
    |> handle_json_result()
  end

  def handle_json_result(result) do
    case result do
      {:ok, {{_, 200, _}, _, body}} ->
        json = to_string(body) |> :json.decode()
        {:ok, json}

      {:ok, {{_, status_code, _}, _, body}} ->
        {:error, "GitHub API returned status #{status_code}: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
