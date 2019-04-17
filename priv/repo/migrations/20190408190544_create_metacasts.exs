defmodule Changelog.Repo.Migrations.CreateMetacasts do
  use Ecto.Migration

  def change do
    create table(:metacasts) do
      add :name, :string, null: false
      add :description, :text
      add :keywords, :string
      add :cover, :string

      add :included_podcasts, :map
      add :excluded_podcasts, :map
      add :included_topics, :map
      add :excluded_topics, :map

      timestamps()
    end

  end
end
