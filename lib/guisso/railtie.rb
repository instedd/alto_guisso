require_relative "rails/routes"
require_relative "../../app/helpers/guisso/application_helper"

class Guisso::Railtie < Rails::Railtie
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
  end

  config.to_prepare do
    ApplicationController.helper Guisso::ApplicationHelper
  end
end
