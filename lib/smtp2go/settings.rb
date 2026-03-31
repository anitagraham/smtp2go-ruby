require 'smtp2go/version'

module Smtp2go
  API_ROOT = 'https://api.smtp2go.com/v3/'.freeze
  API_SEND_URL = 'email/send'.freeze
  API_BATCH_URL = 'email/batch'.freeze
  SEND_ENDPOINT = API_ROOT + API_SEND_URL
  BATCH_ENDPOINT = API_ROOT + API_BATCH_URL
  BATCH_MAX = 1000
  TEMPLATE_KEYS = %i(id data).freeze
  HEADERS = {
    'Content-Type' => 'application/json',
    'X-Smtp2go-Api' => 'smtp2go-ruby',
    'X-Smtp2go-Api-Version' => VERSION
  }.freeze
end
