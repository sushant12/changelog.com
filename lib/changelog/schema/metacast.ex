defmodule Changelog.Metacast do
  use Changelog.Schema

  alias Changelog.Files

  defmodule PodcastReference do
    use Changelog.Schema
    @primary_key false
    embedded_schema do
      field :podcast_id, :integer
      field :position, :integer
    end

    def changeset(struct, attrs), do: cast(struct, attrs, __MODULE__.__schema__(:fields))
  end

  defmodule TopicReference do
    use Changelog.Schema
    @primary_key false
    embedded_schema do
      field :topic_id, :integer
      field :position, :integer
    end

    def changeset(struct, attrs), do: cast(struct, attrs, __MODULE__.__schema__(:fields))
  end

  schema "metacasts" do
    field :name, :string
    field :description, :string
    field :keywords, :string

    field :cover, Files.Cover.Type

    embeds_many :included_podcasts, PodcastReference, on_replace: :delete
    embeds_many :excluded_podcasts, PodcastReference, on_replace: :delete

    embeds_many :included_topics, TopicReference, on_replace: :delete
    embeds_many :excluded_topics, TopicReference, on_replace: :delete

    timestamps()
  end

  def file_changeset(metacast, attrs \\ %{}), do: cast_attachments(metacast, attrs, [:cover])

  def insert_changeset(metacast, attrs \\ %{}) do
    metacast
    |> cast(attrs, ~w(name description keywords)a)
    |> validate_required([:name])
    |> cast_embed(:included_podcasts)
    |> cast_embed(:excluded_podcasts)
    |> cast_embed(:included_topics)
    |> cast_embed(:excluded_topics)
  end

  def update_changeset(metacast, attrs \\ %{}) do
    metacast
    |> insert_changeset(attrs)
    |> file_changeset(attrs)
  end
end
