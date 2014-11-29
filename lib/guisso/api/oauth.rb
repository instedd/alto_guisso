module Guisso
  class Api
    class Oauth < Api
      def initialize(access_token, host, https)
        @token = access_token
        @host = host
        self.use_https = https
      end

      protected

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

        # if method == :get
          # response = @token.get url(url, query) #, nil, processed_payload, nil
          # response = @token.get method, url(url, query)#, nil, processed_payload, nil
        response = @token.httpclient.request method, url(url, query), nil, processed_payload, nil
        # else
          # raise "not supported #{request}"
        # end

        if method == :post && [301, 302, 307].include?(response.code)
          self.do_get(response.headers["Location"])
        else
          response
        end
      end
    end
  end
end
