module Guisso
  module ApplicationHelper
    def guisso_sign_in_path_for(mapping)
      if Guisso.enabled?
        method = "#{mapping}_omniauth_authorize_path"
        send method, :instedd
      else
        new_session_path mapping
      end
    end

    def guisso_sign_up_path_for(mapping)
      if Guisso.enabled?
        method = "#{mapping}_omniauth_authorize_path"
        send method, :instedd, signup: true
      else
        new_registration_path mapping
      end
    end

    def guisso_sign_out_path_for(mapping, options = {})
      if Guisso.enabled?
        "#{Guisso.sign_out_url}?#{options.to_query}"
      else
        destroy_session_path(mapping)
      end
    end

    def guisso_settings_path(mapping)
      if Guisso.enabled?
         Guisso.settings_url
      else
        edit_registration_path(mapping)
      end
    end
  end
end
