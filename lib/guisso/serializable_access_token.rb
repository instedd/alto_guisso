require 'rack/oauth2'

module Rack
  module OAuth2
    class AccessToken
      def _dump(level)
        Marshal.dump(token_response)
      end

      def self._load(args)
        new(Marshal.load(args))
      end
    end
  end
end
