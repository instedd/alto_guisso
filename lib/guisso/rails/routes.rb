module ActionDispatch::Routing
  class Mapper
    def guisso_for(mapping)
      if Guisso.enabled? && defined?(Devise)
        mapping = Devise.mappings[mapping].name

        ActionController::Base.class_eval <<-METHODS, __FILE__, __LINE__ + 1
          before_filter :check_guisso_cookie
          def check_guisso_cookie
            guisso_email = cookies[:guisso]
            if current_#{mapping} && current_#{mapping}.email != guisso_email
              sign_out current_#{mapping}
            elsif !current_#{mapping} && guisso_email.present?
              redirect_to_guisso
            end
          end

          def authenticate_#{mapping}_with_guisso!(*args)
            if current_#{mapping}
              guisso_email = cookies[:guisso]
              if guisso_email == current_#{mapping}.email
                authenticate_#{mapping}_without_guisso!(*args)
              else
                sign_out current_#{mapping}
                redirect_to_guisso
              end
            else
              redirect_to_guisso
            end
          end
          alias_method_chain :authenticate_#{mapping}!, :guisso

          def authenticate_api_#{mapping}!
            email = env["guisso.user"]
            user = #{mapping.to_s.capitalize}.find_by_email email
            if user
              sign_in user
            else
              return head :forbidden unless request.authorization && request.authorization =~ /^Basic (.*)/m
              email, password = Base64.decode64($1).split(/:/, 2)
              authorization = Base64.strict_encode64(Guisso.client_id + ":" + Guisso.client_secret)

              client = HTTPClient.new
              response = client.get Guisso.basic_check_url,
                {email: email, password: password},
                {'Authorization' => "Basic " + authorization}
              if response.ok?
                user = #{mapping.to_s.capitalize}.find_by_email email
                sign_in user
              else
                head :forbidden
              end
            end
          end

          def redirect_to_guisso
            redirect_to omniauth_authorize_path("#{mapping}", "instedd")
          end
        METHODS
      else
        ActionController::Base.class_eval <<-METHODS, __FILE__, __LINE__ + 1
          def authenticate_api_#{mapping}!
            authenticate_#{mapping}!
          end
        METHODS
      end
    end
  end
end
