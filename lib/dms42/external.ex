defmodule Dms42.External do
  require Logger

  use Pipe

  @spec tesseract!(String.t(), list(atom())) :: String.t()
  def tesseract!(img_path, langs) when is_list(langs) do
    case send_to_tesseract(img_path, langs) do
      {:error, reason} -> raise reason
      {:ok, ocr} -> ocr
    end
  end

  @spec tesseract!(String.t(), atom()) :: String.t()
  def tesseract!(img_path, lang) do
    case send_to_tesseract(img_path, [lang]) do
      {:error, reason} -> raise reason
      {:ok, ocr} -> ocr
    end
  end

  @spec extract(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def extract(pdf_path) do
    tmp_path = Temp.path!("dms42")

    case System.cmd("pdftotext", ["-eol", "unix", "-nopgbrk", "-q", pdf_path, tmp_path]) do
      {_, 0} ->
        ocr =
          File.read!(tmp_path)
          |> String.trim()

        case ocr do
          nil -> {:error, "Was not able to read the OCR text from the pdf."}
          "" -> {:error, "Was able to read the OCR text from the PDF but the result was empty."}
          x -> {:ok, x}
        end

      {_, x} ->
        {:error, "An error occurred while extracting the PDF from the PDF #{pdf_path}: #{x}"}
    end
  end

  @spec clean_image(String.t(), String.t()) :: {:none, any}
  def clean_image(path, mime_type) do
    Pipe.pipe_matching(
      {:ok, _},
      {:ok, {path, mime_type}}
      |> filter_file
      |> is_corrupted
      |> fix_errors
      |> replace_broken_file
    )
  end

  @spec send_to_tesseract(String.t(), list(atom())) ::
          {:ok, String.t()} | {:warning, String.t()} | {:error, String.t()}
  def send_to_tesseract(path, langs) when is_list(langs) do
    Logger.debug("Processing tesseract on the file #{path} ...")
    args = [path, "stdout", "-l", Enum.join(langs, "+")]

    case System.cmd("tesseract", args, stderr_to_stdout: false, parallelism: true) do
      {txt, 0} -> {:ok, txt |> String.trim()}
      {_, x} -> {:error, "Tesseract has failed with the code #{x}."}
    end
  end

  @spec transform_document(String.t(), String.t(), keyword()) ::
          {:ok, String.t()} | {:error, String.t()}
  def transform_document(file_path, output_path, options \\ []) do
    args = ["12x6+0.5+0", "-unsharp", "white", "-background"]

    args =
      case {Keyword.get(options, :max_width), Keyword.get(options, :max_height),
            Keyword.get(options, :is_thumbnail, false)} do
        {nil, nil, false} -> args
        {nil, _, _} -> raise "You have to specify the height if the width is specified"
        {_, nil, _} -> raise "You have to specify the width if the height is specified"
        {x, y, true} -> ["#{x}x#{y}>", "-thumbnail"] ++ args
        {x, y, false} -> ["#{x}x#{y}>", "-resize"] ++ args
      end

    args =
      case Keyword.get(options, :scale) do
        nil -> args
        x -> ["#{x}%", "-scale"] ++ args
      end

    args =
      case Keyword.get(options, :density) do
        nil -> args
        x -> ["#{x}", "-density"] ++ args
      end

    args =
      case Keyword.get(options, :quality) do
        nil -> args
        x -> ["#{x}", "-quality"] ++ args
      end

    args =
      case Keyword.get(options, :only_first_page) do
        nil -> [file_path | args]
        _ -> ["#{file_path}[0]" | args]
      end

    args = [output_path | args] |> Enum.reverse()

    Logger.debug("Argument passed to convert: #{IO.inspect(args)}")

    cmd_result =
      System.cmd(
        "convert",
        args,
        parallelism: true,
        stderr_to_stdout: false
      )

    case cmd_result do
      {_, 0} -> {:ok, output_path}
      {_, 1} -> {:warning, output_path}
      {_, x} -> {:error, "Was not able to transform the PDF(#{file_path}) to PNG: #{x}"}
    end
  end

  ##### Private members

  @spec filter_file({:ok, {String.t(), String.t()}}) :: {:ok, String.t()} | {:none, String.t()}
  defp filter_file({:ok, {img_path, mime_type}}) do
    case mime_type |> String.downcase() do
      "image/jpeg" -> {:ok, img_path}
      "image/jpg" -> {:ok, img_path}
      _ -> {:none, img_path}
    end
  end

  @spec fix_errors({:ok, String.t()}) :: {:ok, {String.t(), String.t()}} | {:error, String.t()}
  defp fix_errors({:ok, path}) do
    fixed_file = Temp.path!()

    Logger.debug("The file #{path} is corrupted, trying to repair the image file ...")

    {_, code} =
      System.cmd("convert", [path, fixed_file], parallelism: true, stderr_to_stdout: true)

    case code do
      0 -> {:ok, {fixed_file, path}}
      x -> {:error, "Clean was not successful: #{x}"}
    end
  end

  @spec is_corrupted({:ok, String.t()}) :: {:ok, String.t(), boolean} | {:error, String.t()}
  defp is_corrupted({:ok, path}) do
    {output, code} =
      System.cmd("identify", ["-verbose", path], parallelism: true, stderr_to_stdout: true)

    case code do
      0 ->
        case String.contains?(output, "Corrupt") do
          true -> {:ok, path}
          false -> {:none, path}
        end

      _ ->
        {:error, "Was not able to determine whether the image is corrupted."}
    end
  end

  @spec replace_broken_file({:ok, String.t(), String.t()}) ::
          {:ok, String.t()} | {:error, String.t()}
  defp replace_broken_file({:ok, {fixed_file, broken_file}}) do
    Logger.debug("Replacing the broken file #{broken_file} by the file #{fixed_file} ...")

    case File.copy(fixed_file, broken_file) do
      {:ok, _} -> {:ok, broken_file}
      {:error, _} -> {:error, "Was not able to copy the file #{fixed_file} to #{broken_file}."}
    end
  end
end
