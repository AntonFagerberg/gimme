defmodule GimmeSupervisor do
  use Supervisor

  def start_link do
    IO.puts "Supervisor: started"
    Supervisor.start_link(__MODULE__, :ok)
  end

  @poller_name :poller
  @downloader_name :downloader
  @state_name :state

  def init(:ok) do
    %{"url" => url,
      "regex_true" => regex_true,
      "regex_false" => regex_false,
      "scan_time" => scan_time,
      "download_folder" => download_folder
    } = File.read!("config.json") |> Poison.decode!

    {:ok, regex_true} = Regex.compile(regex_true, "i")
    {:ok, regex_false} = Regex.compile(regex_false, "i")

    children = [
      worker(Downloader, [[name: @downloader_name, state: @state_name, download_folder: download_folder]]),
      worker(Poller, [[name: @poller_name, downloader: @downloader_name, url: url, scan_time: scan_time, regex_true: regex_true, regex_false: regex_false]]),
      worker(State, [[name: @state_name]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
