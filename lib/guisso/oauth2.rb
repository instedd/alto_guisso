module Guisso
  def self.validate_oauth2_request(req)
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
    mac_body['user']
  end
end
