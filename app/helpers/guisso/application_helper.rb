module Guisso
  module ApplicationHelper
    def guisso_sign_in_path_for(mapping)
      if Guisso.enabled?
        omniauth_authorize_path(mapping, :instedd)
      else
        new_session_path mapping
      end
    end

    def guisso_sign_out_path_for(mapping, options = {})
      if Guisso.enabled?
        "#{Guisso.sign_out_url}?#{options.to_query}"
      else
        destroy_session_path(mapping)
      end
    end
  end
end
