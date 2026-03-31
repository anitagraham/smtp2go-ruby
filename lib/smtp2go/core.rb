require 'json'
require 'httparty'
require 'smtp2go/exceptions'
require 'smtp2go/settings'

module Smtp2go
  # Ruby Library for interacting with the smtp2go API
  class Smtp2goClient
    attr_reader :api_key, :headers, :send_endpoint, :batch_endpoint
    def initialize (**options)
      @api_key = options[:api_key] || ENV['SMTP2GO_API_KEY']
      @headers = {**HEADERS, "X-Smtp2go-Api-Key" => api_key}
      @send_endpoint = SEND_ENDPOINT
      @batch_endpoint = BATCH_ENDPOINT
      raise Smtp2goAPIKeyException unless api_key
    end

  end

  # @param sender [String] the from email address
  # @param recipients [Array <String>] the email address of the recipient(s)
  # @param subject [String] the email subject
  # @param text [String] the email text content (optional if html or template is passed)
  # @param html [String] the email html content (optional if text or template is passed)
  # @param template [Hash]{id:, data:} the template id and template data (optional if html or text is passed)
  # @return [Smtp2goResponse] response object


  def send(sender:, recipients:, subject:, template: {}, text: nil, html: nil)
    template.compact!
    raise Smtp2goParameterException unless [html, text, template].any?
    raise Smtp2goTemplateException unless verify_template(template)

    payload = {
      api_key: api_key,
      sender: sender,
      recipients: recipients,
      to: recipients,
      subject: subject,
      text_body: text,
      html_body: html,
      template_id: template[:id] || nil,
      template_data: template[:data] || nil
    }.compact
    submit_to_smtp2go(send_endpoint, payload)
  end

  def batch(emails)
    ap "Received #{emails.length} emails"
    ap emails.first
    # test_keys = %i(text html template)
    # (valid_entries, invalid_entries) = emails.partition { |email| verify_batch_email(email.values_at(*test_keys)) }
    #
    # unless invalid_entries.empty?
    #   puts "#{invalid_entries.size} invalid entries found"
    #   raise Smtp2goParameterException
    # end

    payload = {
      api_key: api_key,
      emails: emails
    }
    submit_to_smtp2go(batch_endpoint, payload)
  end

  private

  def submit_to_smtp2go(endpoint, payload)
    response = HTTParty.post(
      endpoint,
      body: payload.to_json,
      headers: headers
    )
    Smtp2goResponse.new response
  end

  def verify_batch_email( text: nil, html: nil, template: {})
    ap "Verifying batch email: #{text}, html: #{html}, template: #{template}"
    template.compact!
    result = [html, text, template].any?
    ap result ? "Good" : "Bad"
    result
  end

  def verify_template(template)
    template.empty? || (TEMPLATE_KEYS - template.keys).empty?
  end

  # Wraps response object with smtp2go specific data
  class Smtp2goResponse
    attr_reader :rate_limit

    def initialize(response)
      @response = response
      @rate_limit = RateLimit.new @response.headers
    end

    def json
      JSON.parse @response.body
    end

    def success?
      json['data']['succeeded'] ? true : false
    end

    def errors
      json['data']['error']
    end

    def request_id
      json['request_id']
    end

    def status_code
      @response.code
    end
  end

  # Rate limiting class to be attached to response
  class RateLimit
    attr_reader :limit, :remaining, :reset
    def initialize(headers)
      @limit = headers['x-ratelimit-limit']
      @remaining = headers['x-ratelimit-remaining']
      @reset = headers['x-ratelimit-reset']
    end
  end
end
