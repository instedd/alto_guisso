require "uri"

module Guisso
  def self.trusted_resource(url, user_email)
    TrustedResource.new(url, user_email)
  end

  class TrustedResource
    def initialize(url, user_email)
      @uri = URI(url)
      guisso_uri = URI(Guisso.url)

      client = Rack::OAuth2::Client.new(
        identifier: Guisso.client_id,
        secret: Guisso.client_secret,
        host: guisso_uri.host,
        port: guisso_uri.port,
        scheme: guisso_uri.scheme,
      )
      client.scope = %W(app=#{@uri.host} user=#{user_email})
      @token = client.access_token!
    end

    def get(path)
      @token.get absolute_url(path)
    end

    def absolute_url(path)
      @uri + path
    end
  end
end
