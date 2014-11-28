require "uri"

module Guisso
  class << self
    def setup! options={}
      @config = YAML.load_file("#{Rails.root}/config/guisso.yml") rescue {}
      @config.merge! options
    end

    def enabled?
      @config["enabled"]
    end

    def url
      @config["url"]
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
      @config["client_id"]
    end

    def client_secret
      @config["client_secret"]
    end
  end
end
