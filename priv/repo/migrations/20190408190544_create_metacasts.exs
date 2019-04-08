defmodule Changelog.Repo.Migrations.CreateMetacasts do
  use Ecto.Migration

  def change do
    create table(:metacasts) do
      add :name, :string, null: false
      add :description, :text
      add :keywords, :string
      add :cover, :string

      add :included_podcasts, {:array, :integer}, default: []
      add :excluded_podcasts, {:array, :integer}, default: []
      add :included_topics, {:array, :integer}, default: []
      add :excluded_topics, {:array, :integer}, default: []

      timestamps()
    end

  end
end
