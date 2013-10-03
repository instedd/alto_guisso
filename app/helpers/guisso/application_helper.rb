module Guisso
  module ApplicationHelper
    def guisso_sign_in_path_for(mapping)
      if Guisso.enabled?
        omniauth_authorize_path(mapping, :instedd)
      else
        new_session_path mapping
      end
    end

    def guisso_sign_out_path
      Guisso.sign_out_url
    end

    def link_to_guisso_sign_out(text, options = {})
      link_to text, guisso_sign_out_path, options.merge(method: :delete)
    end
  end
end
