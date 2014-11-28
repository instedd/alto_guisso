# alto_guisso

Alto Guisso allows connecting your application with Guisso (Instedd's Single Sign On).

It allows OAuth and Basic authentication with Guisso credentials.

## Installation

Add this line to your application's Gemfile:

    gem 'alto_guisso', github: "instedd/alto_guisso", branch: 'master'

And this ones if you are missing any of them:

* ruby-openid
* rack-oauth2
* omniauth
* omniauth-openid

And then execute:

    $ bundle

## Usage

You can get a rest client with:

    Guisso.trusted_resource(url, user_email).get(path)
    Guisso.trusted_resource(url, user_email).post(path, body)  {|response, request, result| response }

And get a bearer token with:

    Guisso.generate_bearer_token(user_email)

## Config File

Alto Guisso expects a config file named `guisso.yml` on Rails config path, but it can be initialized with an optional hash:

    Guisso.setup! "enabled" => true, "url" => "www.example.com", "client_id" => "...", "client_secret" => "..."
