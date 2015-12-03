defmodule ExMangaDownloadr.CLI do
  alias ExMangaDownloadr.Workflow
  require ExMangaDownloadr.DumpMacro

  def main(args) do
    args
    |> parse_args
    |> process
  end

  defp parse_args(args) do
    parse = OptionParser.parse(args,
      switches: [name: :string, url: :string, directory: :string, source: :string],
      aliases: [n: :name, u: :url, d: :directory, s: :source]
    )
    case parse do
      {[name: manga_name, url: url, directory: directory, source: source], _, _} -> process(manga_name, url, directory, source)
      {[name: manga_name, directory: directory], _, _} -> process(manga_name, directory)
      {_, _, _ } -> process(:help)
    end
  end

  defp process(:help) do
    IO.puts """
      usage:
        ./ex_manga_downloadr -n boku-wa-ookami -u http://www.mangareader.net/boku-wa-ookami -d /tmp/boku-wa-ookami -s mangareader

      source can be:
        - mangareader
        - mangafox

      or just to compile the PDFs (if already finished downloading)
        ./ex_manga_downloadr -n boku-wa-ookami -d /tmp/boku-wa-ookami
    """
    System.halt(0)
  end

  defp process(manga_name, url, directory, source) do
    File.mkdir_p!(directory)

    images_list = DumpMacro.managed_state directory, [url, source]
      |> Workflow.chapters
      |> Workflow.pages
      |> Workflow.images_sources 

    images_list
      |> Workflow.process_downloads(directory)
      |> Workflow.optimize_images
      |> Workflow.compile_pdfs(manga_name)
      |> finish_process
  end

  defp process(manga_name, directory) do
    IO.puts "Just going to compile PDFs."

    directory
      |> Workflow.compile_pdfs(manga_name)
      |> finish_process
  end

  defp finish_process(directory) do
    IO.puts "Finished, please check your PDF files at #{directory}."
    System.halt(0)
  end
end
