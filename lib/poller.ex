defmodule Poller do
  use GenServer

  def start_link(config) do
    IO.puts "Poller: started"
    GenServer.start_link(__MODULE__, {:ok, config}, name: config[:name])
  end

  def init({:ok, config}) do
    ping(config[:scan_time])

    {:ok, config}
  end

  defp ping(timeout) do
    Process.send_after(:poller, :ping, timeout)
  end

  def handle_info(:ping, config) do
    {:ok, %HTTPoison.Response{body: feed, status_code: 200}} = HTTPoison.get(config[:url])

    Quinn.parse(feed)
      |> Quinn.find(:item)
      |> Enum.map(fn item -> {Quinn.find(item, :title), Quinn.find(item, :link)} end)
      |> Enum.reject(fn {title, link} -> Enum.empty?(title) or Enum.empty?(link) or Enum.empty?(hd(title).value) or Enum.empty?(hd(link).value) end)
      |> Enum.map(fn {title, link} -> {hd(hd(title).value), hd(hd(link).value)} end)
      |> Enum.filter(fn {title, _} -> Regex.match?(config[:regex_true], title) end)
      |> Enum.reject(fn {title, _} -> Regex.match?(config[:regex_false], title) end)
      |> Enum.each(fn {_, link} -> Downloader.download(config[:downloader], link) end)

    ping(config[:scan_time])

    {:noreply, config}
  end
end
