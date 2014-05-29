module Guisso
  def self.validate_oauth2_request(req)
    token_body = Rails.cache.fetch(req.access_token, expires_in: 60) do
      response = HTTPClient.new.get Guisso.trusted_token_url,
              identifier: Guisso.client_id,
              secret: Guisso.client_secret,
              token: req.access_token

      return nil unless response.status == 200

      JSON.parse response.body
    end

    case req
    when Rack::OAuth2::Server::Resource::Bearer::Request
      # Nothing to do
    when Rack::OAuth2::Server::Resource::MAC::Request
      token = Rack::OAuth2::AccessToken::MAC.new(
        access_token: req.access_token,
        mac_key: token_body['mac_key'],
        mac_algorithm: token_body['mac_algorithm'],
      )
      token.verify!(req)
    else
      raise "Unknown token type: #{token_body['token_type']}"
    end

    token_body['user']
  end

  def self.generate_bearer_token(user_email)
    uri = Guisso.uri
    client = Rack::OAuth2::Client.new(
      :identifier => Guisso.client_id,
      :secret => Guisso.client_secret,
      :host => uri.host,
      :port => uri.port,
      :scheme => uri.scheme,
    )
    client.scope = %W(user=#{user_email} token_type=bearer never_expires=true)
    client.access_token!.access_token
  end
end
