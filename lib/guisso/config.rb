require "uri"

module Guisso
  class << self
    def setup! options={}
      if defined?(::Settings) && (guisso = ::Settings.guisso)
        @config = guisso.to_h
      else
        @config = YAML.load_file("#{Rails.root}/config/guisso.yml") rescue {}
      end
      @config.merge! options
    end

    def enabled?
      ENV["GUISSO_ENABLED"] == "true" || @config["enabled"]
    end

    def url
      ENV["GUISSO_URL"] || @config["url"]
    end

    def uri
      URI.parse url
    end

    def openid_url
      "#{url}/openid"
    end

    def sign_out_url
      "#{url}/users/sign_out"
    end

    def settings_url
      "#{url}/users/edit"
    end

    def trusted_token_url
      "#{url}/oauth2/trusted_token"
    end

    def basic_check_url
      "#{url}/basic/check"
    end

    def admin_tokens_url
      "#{url}/access_tokens"
    end

    def client_id
      ENV["GUISSO_CLIENT_ID"] || @config["client_id"]
    end

    def client_secret
      ENV["GUISSO_CLIENT_SECRET"] || @config["client_secret"]
    end
  end
end
