defmodule State do
  use GenServer

  def start_link(config) do
    IO.puts "State: started"
    GenServer.start_link(__MODULE__, {:ok, []}, name: config[:name])
  end

  def store(name, link) do
    GenServer.call(name, {:store, link})
  end

  def member?(name, link) do
    GenServer.call(name, {:member, link})
  end

  def init({:ok, state}) do
    {:ok, state}
  end

  def handle_call({:member, link}, _from, state) do
    {:reply, Enum.member?(state, link), state}
  end

  def handle_call({:store, link}, _from, state) do
    if (Enum.member?(state, link)) do
      {:reply, :ok, state}
    else
      new_state = Enum.take([link] ++ state, 1000)
      {:reply, :ok, new_state}
    end
  end
end
