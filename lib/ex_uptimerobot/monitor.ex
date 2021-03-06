defmodule ExUptimerobot.Monitor do
  @moduledoc """
  Interact with Monitor-related API methods.
  """
  alias ExUptimerobot.Request
  alias Poison.Parser

  ## API PATHS

  @doc """
  Get data for all monitors, or a set of monitors as specified by params.

  ## Example

      ExUptimerobot.Monitor.get_monitors()
      {:ok, %{"monitors" => [%{"create_datetime" => 0, "friendly_name" => "Elixir Lang"}]}

  """
  @spec get_monitors([tuple]) :: tuple()
  def get_monitors(params \\ []) do
    with {:ok, body} <- Request.post("getMonitors", params),
         {:ok, body} <- Parser.parse(body)
    do
      {:ok, body}
    else
      {:error, reason} -> {:error, reason}
      _                -> {:error, "Error getting monitors"}
    end
  end

  @doc """
  Add a new monitor with given parameters.

  Three parameters are required: `friendly_name`, `url` and `type`.

  ## Example

      ExUptimerobot.Monitor.new_monitor([friendly_name: "Elixir Lang", url: "http://elixir-lang.org/", type: 1])
      {:ok, response}

  """
  @spec new_monitor([tuple]) :: tuple()
  def new_monitor(params \\ [])
  def new_monitor(params) when is_list(params) do
    with {:ok, body}  <- Request.post("newMonitor", params),
         {:ok, body}  <- Parser.parse(body),
         {:ok, resp}  <- Request.response_status?(body)
    do
      {:ok, resp}
    else
      {:error, reason} -> {:error, reason}
      _                -> {:error, "Error adding monitor"}
    end
  end
  def new_monitor(_params), do: {:error, "Params not a keyword list"}

  @doc """
  Delete an existing monitor by the monitor ID.
  """
  @spec delete_monitor(integer) :: tuple()
  @spec delete_monitor(String.t) :: tuple()
  def delete_monitor(id) do
    with {:ok, body} <- Request.post("deleteMonitor", [format: "json", id: id]),
         {:ok, body} <- Parser.parse(body),
         {:ok, resp} <- Request.response_status?(body)
    do
      {:ok, resp}
    else
      {:error, reason} -> {:error, reason}
      _                -> {:error, "Error deleting monitor"}
    end
  end

  @doc """
  Reset (delete all stats and response time data) a monitor by the monitor ID.
  """
  @spec reset_monitor(integer) :: tuple()
  @spec reset_monitor(String.t) :: tuple()
  def reset_monitor(id) do
    with {:ok, body} <- Request.post("resetMonitor", [format: "json", id: id]),
         {:ok, body} <- Parser.parse(body),
         {:ok, resp} <- Request.response_status?(body)
    do
      {:ok, resp}
    else
      {:error, reason} -> {:error, reason}
      _                -> {:error, "Error resetting monitor"}
    end
  end

  ## HELPERS & CONVENIENCE FUNCTIONS

  @doc """
  Returns `{:ok, values}` where `values` is a list of each values for given key
  per project.

  ## Example

      ExUptimerobot.Monitor.list_values("url")
      {:ok, ["http://elixir-lang.org/", "https://www.erlang.org/"]}

  """
  @spec list_values(String.t) :: tuple()
  def list_values(key) when is_binary(key) do
    if Enum.member?(monitor_keys(), key) do
      case get_monitors() do
        {:ok, body} ->
          {:ok,
            Enum.reduce(get_in(body, ["monitors"]), [], fn(x, acc) ->
              [x[key] | acc]
            end)
          }
        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, "Not a valid key"}
    end
  end
  def list_values(_key), do: {:error, "Provided key not a string"}

  @doc """
  Check if a given URL is being monitored.
  """
  @spec is_monitored?(String.t) :: boolean() | tuple()
  def is_monitored?(url) when is_binary(url) do
    case list_values("url") do
      {:ok, body} -> Enum.member?(body, url)
      {:error, reason} -> {:error, reason}
    end
  end
  def is_monitored?(_url), do: {:error, "Invalid URL format"}

  # Provide a list of possible monitor keys
  defp monitor_keys do
    ["id",
    "friendly_name",
    "url",
    "type",
    "sub_type",
    "keyword_type",
    "keyword_value",
    "http_username",
    "http_password",
    "port",
    "interval",
    "status",
    "monitor_group",
    "is_group_main",
    "logs"]
  end
end
