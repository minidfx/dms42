defmodule Dms42.TransactionHelper do
  require Logger

  @spec commit!(transaction :: Ecto.Multi.t()) :: no_return()
  def commit!(transaction) do
    case Dms42.Repo.transaction(transaction) do
      {:error, table, _, _} -> raise("An error occurred while processing the transaction on the table #{table}")
      {:error, _} -> raise("Cannot commit the transaction.")
      {:ok, _} -> Logger.info("Successfully executed the transaction")
    end
  end
end
