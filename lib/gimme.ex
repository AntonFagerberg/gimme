defmodule Gimme do

  defp loop(url, regex_true, regex_false, download_folder, scan_time) do
    Task.start(fn ->
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{body: rss, status_code: 200}} ->
          parsed = Quinn.parse(rss)
          |> Quinn.find(:item)
          |> Enum.map(fn(item) -> {Quinn.find(item, :title), Quinn.find(item, :link)} end)
          |> Enum.reject(fn({title, link}) -> Enum.empty?(title) or Enum.empty?(link) or Enum.empty?(hd(title).value) or Enum.empty?(hd(link).value) end)
          |> Enum.map(fn({title, link}) -> {hd(hd(title).value), hd(hd(link).value)} end)
          |> Enum.filter(fn({title, _}) -> Regex.match?(regex_true, title) end)
          |> Enum.reject(fn({title, _}) -> Regex.match?(regex_false, title) end)

          Enum.each(parsed, fn({title, link}) ->

            case HTTPoison.get(link) do
              {:ok, %HTTPoison.Response{body: file_data, headers: headers, status_code: 200}} ->

                filename = case Regex.run(~r/filename="(.*)"/, headers["Content-Disposition"]) do
                  [_full_match, match] -> match
                  _ -> :base64.encode(:crypto.strong_rand_bytes(16))
                end

                download_path = download_folder <> filename

                if (!File.exists?(download_path)) do
                  case File.write(download_path, file_data) do
                    :ok -> IO.puts("Saved file: #{filename}")
                    {:error, reason} -> IO.puts("Could not save file (#{reason}): #{filename}")
                  end
                end

              {:ok, %HTTPoison.Response{status_code: status_code}} ->
                IO.puts("File server responded with code: #{status_code}")

              {:error, %HTTPoison.Error{reason: reason}} ->
                IO.puts("Unable to download #{title}: #{inspect(reason)}")
            end
          end)

        {:ok, %HTTPoison.Response{status_code: status_code}} ->
          IO.puts("Server feed URL responded not-ok code: #{status_code}")

        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.puts("Unable to download feed: (#{inspect(reason)})")
      end
    end)

    :timer.sleep(scan_time)
    loop(url, regex_true, regex_false, download_folder, scan_time)
  end

  def run() do
    %{"url" => url,
      "regex_true" => regex_true,
      "regex_false" => regex_false,
      "scan_time" => scan_time,
      "download_folder" => download_folder
    } = File.read!("config.json") |> Poison.decode!

    regex_true = Regex.compile!(regex_true)
    regex_false = Regex.compile!(regex_false)

    if (String.at(download_folder, -1) != "/") do
      download_folder = download_folder <> "/"
    end

    loop(url, regex_true, regex_false, download_folder, scan_time)
  end
end
