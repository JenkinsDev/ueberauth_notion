defmodule Ueberauth.Strategy.Notion do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Notion.
  """

  use Ueberauth.Strategy,
    uid_field: :id,
    default_scope: "",
    send_redirect_uri: true,
    oauth2_module: Ueberauth.Strategy.Notion.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the Notion authentication page.
  """
  def handle_request!(conn) do
    opts =
      []
      |> with_state_param(conn)
      |> with_redirect_uri(conn)

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Notion.

  When there is a failure from Notion, the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Notion is
  returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token_response = apply(module, :get_token!, [
      [code: code, redirect_uri: callback_url(conn), grant_type: "authorization_code"]
    ])

    if token_response.access_token == nil do
      set_errors!(conn, [
        error(token_response.error, token_response.error_description)
      ])
    else
      authorization_fields = %{
        access_token: token_response.access_token,
        refresh_token: token_response.refresh_token,
        expires_at: token_response.expires_at,
        token_type: token_response.token_type
      }
      
      conn
      |> put_private(:notion_authorization, authorization_fields)
      |> put_private(:notion_other_params, Map.get(token_response, :other_params, %{}))
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Notion
  response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:notion_authorization, nil)
    |> put_private(:notion_other_params, nil)
  end

  @doc """
  Includes the credentials from the GitHub response.
  """
  def credentials(conn) do
    auth_data = conn.private.notion_authorization

    %Credentials{
      token: auth_data.access_token,
      refresh_token: auth_data.refresh_token,
      expires: !!auth_data.expires_at,
      expires_at: auth_data.expires_at,
      token_type: auth_data.token_type
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth`
  struct.
  """
  def info(conn) do
    other_data = conn.private.notion_other_params

    %Info{
      name: other_data["owner"]["user"]["name"],
      email: other_data["owner"]["user"]["person"]["email"],
      image: other_data["owner"]["user"]["avatar_url"]
    }
  end

  def extra(conn) do
    other_data = conn.private.notion_other_params

    %Extra{
      raw_info: %{
        bot_id: Map.get(other_data, "bot_id", ""),
        duplicated_template_id: Map.get(other_data, "duplicated_template_id", ""),
        owner: Map.get(other_data, "owner", {}),
        workspace: %{
          id: Map.get(other_data, "workspace_id", ""),
          icon: Map.get(other_data, "workspace_icon", ""),
          name: Map.get(other_data, "workspace_name", "")
        }
      }
    }
  end

  defp fetch_uid(key, conn) do
    conn.private.notion_other_params[key]
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp with_redirect_uri(opts, conn) do
    if option(conn, :send_redirect_uri) do
      opts |> Keyword.put(:redirect_uri, callback_url(conn))
    else
      opts
    end
  end
end
