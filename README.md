# Überauth Notion

[![Module Version](https://img.shields.io/hexpm/v/ueberauth_notion.svg)](https://hex.pm/packages/ueberauth_notion)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ueberauth_notion/)

> Notion OAuth2 strategy for Überauth.

## Installation

1.  Setup your application by following the [following guide](https://developers.notion.com/docs/create-a-notion-integration).

2.  Add `:ueberauth_notion` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [
        {:ueberauth_notion, "~> 0.1.1"}
      ]
    end
    ```

3.  Add Notion to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        notion: {Ueberauth.Strategy.Notion, []}
      ]
    ```

4.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Notion.OAuth,
      client_id: System.get_env("NOTION_CLIENT_ID"),
      client_secret: System.get_env("NOTION_CLIENT_SECRET"),
      redirect_uri: System.get_env("NOTION_REDIRECT_URI")
    ```

    Or, to read the client credentials at runtime:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Github.OAuth,
      client_id: {:system, "NOTION_CLIENT_ID"},
      client_secret: {:system, "NOTION_CLIENT_SECRET"},
      redirect_uri: {:system, "NOTION_REDIRECT_URI"}
    ```

5.  Include the Überauth plug in your router:

    ```elixir
    defmodule MyApp.Router do
      use MyApp.Web, :router

      pipeline :browser do
        plug Ueberauth
        ...
       end
    end
    ```

6.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

7.  Your controller needs to implement callbacks to deal with `Ueberauth.Auth`
    and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/notion
