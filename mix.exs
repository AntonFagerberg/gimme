defmodule Gimme.Mixfile do
  use Mix.Project

  def project do
    [app: :gimme,
     version: "1.0.0",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger, :httpoison], mod: {Gimme, []}]
  end

  defp deps do
    [
      {:poison, "~> 3.0"},
      {:quinn, "~> 1.0"},
      {:httpoison, "~> 0.10"}
    ]
  end
end
