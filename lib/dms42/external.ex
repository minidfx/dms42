defmodule Dms42.External do
  require Logger

  def tesseract!(img_path, lang: lang) when not is_list(lang) do
    exec_tesseract(img_path, [lang])
  end

  def tesseract!(img_path, lang: langs) do
    exec_tesseract(img_path, langs)
  end

  def extract(pdf_path) do
    Temp.track!()
    tmp_path = Temp.path!("dms42")

    case System.cmd("pdftotext", ["-eol", "unix", "-nopgbrk", "-q", pdf_path, tmp_path]) do
      {_, 0} ->
        ocr =
          File.read!(tmp_path)
          |> String.trim()

        case ocr do
          nil -> {:error, "No result"}
          "" -> {:error, "Empty result"}
          x -> {:ok, x}
        end

      {_, error} ->
        {:error, error}
    end
  end

  defp exec_tesseract(img_path, langs) do
    langs_flatten = langs_str(langs)
    args = [img_path, "stdout", "-l"]
    Logger.info("Languages passed to tesseract: #{langs_flatten}")
    {txt, 0} = System.cmd("tesseract", args, stderr_to_stdout: false)
    txt |> String.graphemes() |> String.trim()
  end

  defp langs_str(langs) do
    Enum.join(langs, "+")
  end
end
