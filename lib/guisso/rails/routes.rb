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
                  return authenticate_#{mapping}_without_guisso!(*args)
                else
                  sign_out current_#{mapping}
                  return redirect_to_guisso
                end
              end
              sign_in current_#{mapping}
            elsif params[:format] && params[:format] != :html
              head :unauthorized
            else
              redirect_to_guisso
            end
          end

          def current_#{mapping}_with_guisso
            unless @currrent_#{mapping}
              if request.authorization && request.authorization =~ /^Basic (.*)/m
                email, password = Base64.decode64($1).split(/:/, 2)
                if Guisso.valid_credentials?(email, password)
                  @current_#{mapping} = #{mapping.to_s.capitalize}.find_by_email email
                end
              end
            end

            @current_#{mapping} ||= current_#{mapping}_without_guisso
          end

          unless method_defined?(:authenticate_#{mapping}_without_guisso!)
            alias_method_chain :authenticate_#{mapping}!, :guisso
          end

          unless method_defined?(:current_#{mapping}_without_guisso)
            alias_method_chain :current_#{mapping}, :guisso
          end

          def redirect_to_guisso
            redirect_to #{mapping}_omniauth_authorize_path(:instedd)
          end

          def authenticate_api_#{mapping}!
            return if current_#{mapping}

            if (req = env["guisso.oauth2.req"])
              email = Guisso.validate_oauth2_request(req)
              if email
                user = #{mapping.to_s.capitalize}.find_by_email email
                if user
                  @current_#{mapping} = user
                  return
                end
              end
            elsif request.authorization && request.authorization =~ /^Basic (.*)/m
              email, password = Base64.decode64($1).split(/:/, 2)
              if Guisso.valid_credentials?(email, password)
                @current_#{mapping} = #{mapping.to_s.capitalize}.find_by_email email
                return
              end
            end

            head :unauthorized
          end
        METHODS
      else
        ActionController::Base.class_eval <<-METHODS, __FILE__, __LINE__ + 1
          def authenticate_#{mapping}_without_guisso!
            authenticate_#{mapping}!
          end

          def authenticate_api_#{mapping}!
            authenticate_#{mapping}!
          end
        METHODS
      end
    end
  end
end
