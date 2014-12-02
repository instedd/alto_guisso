require "guisso/api/basic_auth"
require "guisso/api/oauth"

module Guisso
  class ApiError < StandardError
    attr_reader :message
    attr_reader :error_code
    attr_reader :http_status_code

    def initialize(opts)
      @message = opts[:message] || "API exception"
      @error_code = opts[:error_code] || 0
      @http_status_code = opts[:http_status_code] || 0
    end
  end

  class Api
    # RestClient.log = 'stdout'

    def initialize(executor, host, https)
      @executor = executor
      @executor.api = self
      @host = host
      self.use_https = https
    end

    def self.basic_auth(username, password, host = nil, https = nil)
      self.new(BasicAuth.new(username, password), host, https)
    end

    def self.from_authorization_code(authorization_code, redirect_uri, host = nil, https = nil)
      self.from_oauth_client(host, https, redirect_uri: redirect_uri) do |client|
        client.authorization_code = authorization_code
        {}
      end
    end

    def self.trusted(user_email, host = nil, https = nil)
      from_oauth_client(host || self.default_host, https.nil? ? self.default_use_ssl : https) do |client, app_host|
        {
          client_auth_method: :oauth2, # just anything other than :basic
          scope: %W(app=#{app_host} user=#{user_email})
        }
      end
    end

    def self.from_oauth_client(host, https, options = {})
      if host !~ /\Ahttp:|https:/
        app_uri = URI("http://#{host}")
      else
        app_uri = URI(host)
      end

      if app_uri.default_port == app_uri.port
        app_host = app_uri.host
      else
        app_host = "#{app_uri.host}:#{app_uri.port}"
      end

      guisso_uri = URI(Guisso.url)

      client = Rack::OAuth2::Client.new(options.merge({
        identifier: Guisso.client_id,
        secret: Guisso.client_secret,
        host: guisso_uri.host,
        port: guisso_uri.port,
        scheme: guisso_uri.scheme,
      }))
      access_token_option = yield client, app_host

      access_token = client.access_token! access_token_option

      oauth access_token, host, https
    end

    def self.oauth(access_token, host, https)
      self.new(Oauth.new(access_token), host, https)
    end

    def use_https=(https)
      @protocol = https ? 'https' : 'http'
    end

    def url(url='', query = nil)
      if url !~ /\Ahttp:|https:/
        url = "/#{url}" unless url.start_with? "/"
        url = "#{@protocol}://#{@host}#{url}"
      end

      if query && !query.empty?
        if query.is_a?(Hash)
          "#{url}?#{query.to_query}"
        else
          "#{url}?#{query}"
        end
      else
        url
      end
    end

    def get(url, query)
      process_response(do_get(url, query))
    end

    def get_with_payload(url, query = {})
      process_response(execute(:get, url, nil, query))
    end

    def post(url, body = {})
      process_response(execute(:post, url, nil, body))
    end

    def put(url, body = {})
      process_response(execute(:put, url, nil, body))
    end

    def delete(url)
      process_response(execute(:delete, url, nil, nil))
    end

    def json(url, query = {})
      u = url
      q = query

      if u.index("?") && q == {}
        u, q = u.split("?")
        query_bytesize = q.bytesize
      else
        query_bytesize = URI.encode_www_form(q).bytesize
      end

      # TODO maybe setup and option for json extension
      # u = "#{u}.json" unless u.end_with?(".json")

      # Send query in the payload if it'd yield a too long URI
      response = if query_bytesize > 4000
        get_with_payload u, q
      else
        get u, q
      end

      JSON.parse response
    end

    def execute(*args)
      @executor.execute(*args)
    end

    def do_get(url, query = {})
      execute(:get, url, query, nil)
    end

    protected

    def process_response(response)
      return response if response.is_a?(String) # with basic it seems to return the body

      if response.status >= 400
        error_obj = ActiveSupport::JSON.decode response.body

        raise ApiError.new(message: error_obj["message"], error_code: error_obj["error_code"], http_status_code: response.status)
      end

      response.body
    end
  end
end
