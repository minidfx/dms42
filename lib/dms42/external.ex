defmodule Dms42.External do
  require Logger

  def tesseract!(img_path, [lang: lang] = _options) when not is_list(lang) do
    exec_tesseract(img_path, [lang])
  end

  def tesseract!(img_path, [lang: langs] = _options \\ [lang: [:eng]]) do
    exec_tesseract(img_path, langs)
  end

  @spec extract(path :: String.t()) :: {:ok, String.t()} | {:error, any}
  def extract(pdf_path) do
    Temp.track!
    tmp_path = Temp.path!("dms42")
    case System.cmd("pdftotext", [pdf_path, tmp_path]) do
      {_, 0} ->
        ocr = File.read!(tmp_path) |> :unicode.characters_to_binary(:latin1)
                                   |> String.trim
        case ocr do
          nil -> {:error, "No result"}
          "" -> {:error, "Empty result"}
          x -> {:ok, x}
        end
      {_, error} -> {:error, error}
    end
  end

  defp exec_tesseract(img_path, langs) do
    {input, output} = {img_path, "stdout"}
    args = [input, output, "-l", langs_str(langs)]
    {txt, 0} = System.cmd("tesseract", args, stderr_to_stdout: true)
    txt |> String.trim
  end

  defp langs_str(langs) do
    Enum.join(langs, "+")
  end
end
