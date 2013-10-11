module ActionDispatch::Routing
  class Mapper
    def guisso_for(mapping)
      if Guisso.enabled? && defined?(Devise)
        mapping = Devise.mappings[mapping].name

        ActionController::Base.class_eval <<-METHODS, __FILE__, __LINE__ + 1
          unless method_defined?(:check_guisso_cookie)
            before_filter :check_guisso_cookie
          end

          def check_guisso_cookie
            guisso_email = cookies[:guisso]
            if guisso_email
              if current_#{mapping} && current_#{mapping}.email != guisso_email
                sign_out current_#{mapping}
              elsif !current_#{mapping} && guisso_email.present? && guisso_email != "logout"
                redirect_to_guisso
              end
            end
          end

          def authenticate_#{mapping}_with_guisso!(*args)
            if current_#{mapping}
              guisso_email = cookies[:guisso]
              if guisso_email
                if guisso_email == current_#{mapping}.email
                  authenticate_#{mapping}_without_guisso!(*args)
                else
                  sign_out current_#{mapping}
                  redirect_to_guisso
                end
              end
            else
              email = env["guisso.user"]
              user = #{mapping.to_s.capitalize}.find_by_email email
              if user
                sign_in user
              else
                if request.authorization
                  return head :forbidden unless request.authorization =~ /^Basic (.*)/m
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
                else
                  redirect_to_guisso
                end
              end
            end
          end

          unless method_defined?(:authenticate_#{mapping}_without_guisso!)
            alias_method_chain :authenticate_#{mapping}!, :guisso
          end

          def redirect_to_guisso
            redirect_to #{mapping}_omniauth_authorize_path(:instedd)
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
