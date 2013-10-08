# alto_guisso

Alto Guisso allows connecting your application with Guisso (Instedd's Single Sign On).

It provides two funcionalities:

1. Allow users to sign in with Guisso as an OpenId server.
2. Allow OAuth and Basic authentication with Guisso credentials.

## Installation

Add this line to your application's Gemfile:

    gem 'alto_guisso', git: "https://bitbucket.org/instedd/alto_guisso.git"

And then execute:

    $ bundle

## Dependencies

* devise
* ruby-openid
* rack-oauth2
* omniauth
* omniauth-openid

## Usage

### Allow users to sign in with Guisso as an OpenId server

* Require `openid` and some other files:

        # config/application.rb
        require "openid"
        require 'openid/extensions/sreg'
        require 'openid/extensions/pape'
        require 'openid/store/filesystem'

* Add `:omniauthable` to your devise Model

        # app/models/user.rb
        class User < ActiveRecord::Base
          devise :omniauthable, ...
        end

* Create a model to store the OpenId identities:

        # app/models/identity.rb
        class Identity < ActiveRecord::Base
          # t.integer :user_id
          # t.string :provider
          # t.string :token

          belongs_to :user
        end

        # app/models/user.rb
        class User < ActiveRecord::Base
          has_many :identities, dependent: :destroy
        end

* Override Devise's omniauth callbacks controller:

        # config/routes.rb
        devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}

        # app/controllers/omniauth_callbacks_controller.rb
        class OmniauthCallbacksController < Devise::OmniauthCallbacksController
          skip_before_filter :check_guisso_cookie

          def instedd
            generic do |auth|
              {
                email: auth.info['email'],
                # name: auth.info['name'],
              }
            end
          end

          def generic
            auth = env['omniauth.auth']

            if identity = Identity.find_by_provider_and_token(auth['provider'], auth['uid'])
              user = identity.user
            else
              attributes = yield auth

              attributes[:confirmed_at] = Time.now

              user = User.find_by_email(attributes[:email])
              unless user
                password = Devise.friendly_token
                user = User.create!(attributes.merge(password: password, password_confirmation: password))
              end
              user.identities.create! provider: auth['provider'], token: auth['uid']
            end

            sign_in user
            next_url = env['omniauth.origin'] || root_path
            next_url = root_path if next_url == new_user_session_url
            redirect_to next_url
          end
        end

* Define Guisso in your routes for your Devise model:

        # config/routes.rb
        devise_for :users, ...
        # note that here it uses the singular form
        guisso_for :user

* Change the sign in paths to use Guisso:

        # Before:
        link_to "Sign in", new_user_session_path

        # After:
        link_to "Sign in", guisso_sign_in_path_for(:user)

* Change the sign out paths to use Guisso:

        # Before:
        link_to "Sign Out", destroy_user_session_path, method: :delete

        # After:
        link_to "Sign out", guisso_sign_out_path_for(:user, after_sign_out_url: root_url), method: :delete

### Allow OAuth and Basic authentication with Guisso credentials.

In a controller that provides an API endpoint:

        class MyApiController < ApplicationController
          before_filter :authenticate_user!
        end

That is, you don't need to change anything.
