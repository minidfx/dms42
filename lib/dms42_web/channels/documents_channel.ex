defmodule Dms42Web.DocumentsChannel do
  use Dms42Web, :channel

  require Logger

  def join("documents:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
