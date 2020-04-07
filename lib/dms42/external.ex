defmodule Dms42.External do
  require Logger

  use Pipe

  def tesseract!(img_path, lang: lang) when not is_list(lang) do
    case send_to_tesseract(img_path, [lang]) do
      {:error, reason} -> raise reason
      {:ok, ocr} -> ocr
    end
  end

  def tesseract!(img_path, lang: langs) do
    case send_to_tesseract(img_path, langs) do
      {:error, reason} -> raise reason
      {:ok, ocr} -> ocr
    end
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

  def clean_image(path, mime_type) do
    Pipe.pipe_matching(
      {:ok, _},
      {:ok, {path, mime_type}}
      |> filter_file
      |> fix_errors
      |> replace_broken_file
    )
  end

  def send_to_tesseract(path, langs) do
    Logger.info("Will processing tesseract on the file #{path} ...")
    args = [path, "stdout", "-l", Enum.join(langs, "+")]

    case System.cmd("tesseract", args, stderr_to_stdout: false) do
      {txt, 0} -> {:ok, txt |> String.trim()}
      {_, x} -> {:error, "Tesseract has failed with the code #{x}."}
    end
  end

  defp filter_file({:ok, {img_path, mime_type}}) do
    case mime_type |> String.downcase() do
      "image/jpeg" -> {:ok, img_path}
      "image/jpg" -> {:ok, img_path}
      _ -> {:none, img_path}
    end
  end

  defp fix_errors({:ok, img_path}) do
    fixed_file = Temp.path!()

    Logger.info("Trying to repair the image file #{img_path} ...")

    {_, code} =
      System.cmd("jpegtran", ["-perfect", "-copy", "all", "-outfile", fixed_file, img_path])

    case code do
      0 -> {:ok, {fixed_file, img_path}}
      2 -> {:ok, {fixed_file, img_path}}
      x -> {:error, "Clean was not successful: #{x}"}
    end
  end

  defp replace_broken_file({:ok, {fixed_file, broken_file}}) do
    Logger.info("Replacing the broken file #{broken_file} by the file #{fixed_file} ...")

    case File.copy(fixed_file, broken_file) do
      {:ok, _} -> {:ok, broken_file}
      {:error, _} -> {:error, "Was not able to copy the file #{fixed_file} to #{broken_file}."}
    end
  end
end
