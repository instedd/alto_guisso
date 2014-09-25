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
      app.middleware.use Rack::OAuth2::Server::Resource::Bearer, 'Rack::OAuth2' do |req|
        req.env["guisso.oauth2.req"] = req
      end
      app.middleware.use Rack::OAuth2::Server::Resource::MAC, 'Rack::OAuth2' do |req|
        req.env["guisso.oauth2.req"] = req
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
          if req.params['signup']
            oidreq.add_extension(Guisso::OpenID::Extension.new signup: "true")
          end
          open_id_redirect_url_without_guisso(req, oidreq, trust_root, return_to, method, immediate)
        end
        alias_method_chain :open_id_redirect_url, :guisso
      end
    end
  end
end

class Guisso::Engine < Rails::Engine
  config.to_prepare do
    ApplicationController.helper Guisso::ApplicationHelper

    class ::ApplicationController
      def after_sign_out_path_for_with_guisso(resource)
        return_path = after_sign_out_path_for_without_guisso(resource)
        return return_path unless Guisso.enabled?

        return_url = "#{request.protocol}#{request.host_with_port.sub(/:80$/,"")}/#{return_path.sub(/^\//,"")}"
        options = { after_sign_out_url: return_url }
        "#{Guisso.sign_out_url}?#{options.to_query}"
      end
      alias_method_chain :after_sign_out_path_for, :guisso
    end
  end
end
