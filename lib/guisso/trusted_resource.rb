require "uri"

module Guisso
  def self.trusted_resource(url, user_email)
    TrustedResource.new(url, user_email)
  end

  def self.oauth_client
    guisso_uri = Guisso.uri

    Rack::OAuth2::Client.new(
      identifier: Guisso.client_id,
      secret: Guisso.client_secret,
      host: guisso_uri.host,
      port: guisso_uri.port,
      scheme: guisso_uri.scheme,
    )
  end

  class TrustedResource
    def initialize(url, user_email)
      uri = URI(url)
      host_and_port = uri.host
      host_and_port << ":#{uri.port}" unless uri.port == uri.default_port
      @token = Guisso.oauth_client.access_token! scope: %W(app=#{host_and_port} user=#{user_email})
    end

    def get(path)
      @token.get absolute_url(path)
    end

    def post(path, body, &block)
      @token.post absolute_url(path), body: body, &block
    end

    def put(path, body, &block)
      @token.put absolute_url(path), body: body, &block
    end

    def delete(path, &block)
      @token.delete absolute_url(path), &block
    end

    def absolute_url(path)
      Guisso.uri + path
    end
  end
end
