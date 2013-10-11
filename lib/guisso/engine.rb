require_relative "rails/routes"
require_relative "../../app/helpers/guisso/application_helper"

class Guisso::Engine < Rails::Engine
  initializer "guisso.initializer" do |app|
    Guisso.setup!

    if Guisso.enabled?
      begin
        require "devise"

        Devise.setup do |config|
          config.omniauth :open_id, store: OpenID::Store::Filesystem.new("#{Rails.root}/tmp"), name: 'instedd', identifier: Guisso.openid_url, require: 'omniauth-openid'
        end
      rescue LoadError => ex
        puts "Warning: failed loading. #{ex}"
      end

      require 'rack/oauth2'
      app.middleware.use Rack::OAuth2::Server::Resource::MAC, 'Rack::OAuth2' do |req|
        client = HTTPClient.new
        body = client.get_content Guisso.trusted_token_url,
                identifier: Guisso.client_id,
                secret: Guisso.client_secret,
                token: req.access_token
        mac_body = JSON.parse body

        mac_token = Rack::OAuth2::AccessToken::MAC.new(
          access_token: req.access_token,
          mac_key: mac_body['mac_key'],
          mac_algorithm: mac_body['mac_algorithm'],
        )
        mac_token.verify!(req)

        req.env["guisso.user"] = mac_body['user']
      end
    end

    module ::Guisso
      module OpenID
        class Extension < ::OpenID::Extension
          NS_URI = "http://instedd.org/guisso"

          def initialize(args)
            @ns_uri = NS_URI
            @ns_alias = "guisso"
            @args = args
          end

          def get_extension_args
            @args
          end
        end
      end
    end

    class ::Rack::OpenID
      def open_id_redirect_url_with_guisso(req, oidreq, trust_root, return_to, method, immediate)
        if Guisso.enabled?
          if req.params['signup']
            oidreq.add_extension(Guisso::OpenID::Extension.new signup: "true")
          end
        end
        open_id_redirect_url_without_guisso(req, oidreq, trust_root, return_to, method, immediate)
      end
      alias_method_chain :open_id_redirect_url, :guisso
    end
  end

  config.to_prepare do
    ApplicationController.helper Guisso::ApplicationHelper
  end
end
