module Guisso
  class Api
    class Oauth
      attr_accessor :api

      def initialize(access_token)
        @token = access_token
      end

      def execute(method, url, query, payload)
        tmp_dir = "#{Rails.root}/tmp/guisso_api"
        FileUtils.mkdir tmp_dir if !File.exists?(tmp_dir)

        processed_payload = nil

        if payload
          processed_payload = payload

          if processed_payload.is_a?(Hash)
            if processed_payload[:file]
              original_filename = "#{Time.now.getutc.to_i}.csv"

              path = File.join(tmp_dir, original_filename)
              File.open(path, "wb") { |f| f.write(processed_payload[:file].read) }

              processed_payload[:file] = File.open("#{tmp_dir}/#{original_filename}")
            else
              processed_payload = processed_payload.to_query
            end
          end
        end

        response = @token.httpclient.request method, api.url(url, query), nil, processed_payload, nil

        if method == :post && [301, 302, 307].include?(response.code)
          api.do_get(response.headers["Location"])
        else
          response
        end
      end
    end
  end
end
