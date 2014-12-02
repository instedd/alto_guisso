module Guisso
  class Api
    class BasicAuth
      attr_accessor :api

      def initialize(username, password)
        @auth = {username: username, password: password}
      end

      def execute(method, url, query, payload)
        options = {
          :user => @auth[:username],
          :password => @auth[:password],

          :method => method,
          :url => api.url(url, query)
        }

        options[:payload] = payload if payload

        RestClient::Request.execute options do |response, request, result, &block|
          # follow-redirections on POST (required for import wizard)
          # but ignore payload (file)
          if request.method == :post && [301, 302, 307].include?(response.code)
            api.get(response.headers[:location])
          else
            response.return!(request, result, &block)
          end
        end
      end
    end
  end
end
