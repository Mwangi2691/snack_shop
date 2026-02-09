defmodule SnackShop.MixProject do
  use Mix.Project

  def project do
    [
      app: :snack_shop,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {SnackShop.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix core
      {:phoenix, "~> 1.8.1"},
      {:phoenix_ecto, "~> 4.7"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},

      # Assets
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},

      # HTTP & JSON
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},

      # Auth
      {:bcrypt_elixir, "~> 3.0"},
      {:guardian, "~> 2.3"},
      {:ueberauth, "~> 0.10"},
      {:ueberauth_google, "~> 0.10"},

      # Mail
      {:swoosh, "~> 1.16"},

      # Caching
      {:cachex, "~> 3.6"},

      # Telemetry
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},

      # I18n
      {:gettext, "~> 0.26"},

      # Clustering / runtime
      {:dns_cluster, "~> 0.2.0"},

      # Server
      {:bandit, "~> 1.5"},

      # Testing
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_machina, "~> 2.7", only: :test},
      {:httpoison, "~> 2.0"},

      {:faker, "~> 0.17", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind snack_shop", "esbuild snack_shop"],
      "assets.deploy": [
        "tailwind snack_shop --minify",
        "esbuild snack_shop --minify",
        "phx.digest"
      ]
    ]
  end
end
