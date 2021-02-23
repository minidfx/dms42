defmodule Dms42.TransactionHelper do
  require Logger

  @spec commit!(Ecto.Multi.t()) :: :ok | {:error, String.t()}
  def commit!(transaction) do
    case Dms42.Repo.transaction(transaction) do
      {:error, table, _, _} ->
        raise("An error occurred while processing the transaction on the table #{table}")

      {:error, _} ->
        raise("Cannot commit the transaction.")

      {:ok, _} ->
        Logger.info("Successfully executed the transaction")
    end
  end
end
