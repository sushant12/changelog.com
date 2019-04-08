defmodule Changelog.Metacast do
  use Changelog.Schema

  alias Changelog.Files

  schema "metacasts" do
    field :name, :string
    field :description, :string
    field :keywords, :string

    field :included_podcasts, {:array, :integer}
    field :excluded_podcasts, {:array, :integer}

    field :included_topics, {:array, :integer}
    field :excluded_topics, {:array, :integer}

    field :cover, Files.Cover.Type

    timestamps()
  end

  def file_changeset(metacast, attrs \\ %{}), do: cast_attachments(metacast, attrs, [:cover])

  def insert_changeset(metacast, attrs \\ %{}) do
    metacast
    |> cast(attrs, ~w(name description keywords included_podcasts excluded_podcasts included_topics excluded_topics)a)
    |> validate_required([:name])
  end

  def update_changeset(metacast, attrs \\ %{}) do
    metacast
    |> insert_changeset(attrs)
    |> file_changeset(attrs)
  end

end
