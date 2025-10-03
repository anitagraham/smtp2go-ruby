module Smtp2go
  class Smtp2goBaseException < StandardError
  end

  class Smtp2goAPIKeyException < Smtp2goBaseException
    def message
      'Smtp2go requires an Smtp2go api_key as either an environment variable (SMTP2GO_API_KEY) or an initialization option (api_key:)'
    end
  end

  class Smtp2goParameterException < Smtp2goBaseException
    def message
      'send call requires one of text, html or template arguments'
    end
  end

  class Smtp2goTemplateException < Smtp2goBaseException
    def message
      'template must include template id and template data'
    end
  end
end
