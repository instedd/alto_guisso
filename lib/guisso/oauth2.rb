module Guisso
  def self.generate_bearer_token(user_email)
    Guisso.oauth_client.access_token!(scope: %W(user=#{user_email} token_type=bearer never_expires=true)).access_token
  end
end
