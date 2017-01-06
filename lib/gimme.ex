defmodule Gimme do
  use Application

  def start(_type, _args) do
    GimmeSupervisor.start_link
  end

end
