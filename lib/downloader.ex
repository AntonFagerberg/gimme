defmodule Downloader do
  use GenServer

  def start_link(config) do
    IO.puts "Downloader: started"
    GenServer.start_link(__MODULE__, {:ok, config}, name: config[:name])
  end

  def download(name, link) do
    GenServer.call(name, {:download, link})
  end

  def init({:ok, config}) do
    {:ok, config}
  end

  def handle_call({:download, link}, _from, config) do
    if (!State.member?(config[:state], link)) do
      IO.puts("Downloading: #{link}")

      {:ok, %HTTPoison.Response{body: file_data, headers: headers, status_code: 200}} = HTTPoison.get(link)

      {_, content_disposition} = Enum.find(headers, fn {key, _} -> key == "Content-Disposition" end)

      filename =
        case Regex.run(~r/filename="(.*)"/, content_disposition) do
          [_full_match, match] -> match
        end

      download_path = "#{config[:download_folder]}/#{filename}"

      File.write(download_path, file_data)

      State.store(config[:state], link)

      IO.puts("Saved: #{filename}")
    end

    {:reply, :ok, config}
  end
end
