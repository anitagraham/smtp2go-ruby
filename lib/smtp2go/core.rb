require 'json'
require 'httparty'
require 'smtp2go/exceptions'
require 'smtp2go/settings'

module Smtp2go
  # Ruby Library for interacting with the smtp2go API
  class Smtp2goClient

    def initialize (**options)
      @api_key = options[:api_key] || ENV['SMTP2GO_API_KEY']
      raise Smtp2goAPIKeyException unless @api_key

      @headers = { **HEADERS, "X-Smtp2go-Api-Key" => @api_key }
      @send_endpoint = SEND_ENDPOINT
      @batch_endpoint = BATCH_ENDPOINT
      @suppression_endpoint = SUPPRESSION_ENDPOINT
    end

    # @param sender [String] the from email address
    # @param recipients [Array <String>] the email address of the recipient(s)
    # @param subject [String] the email subject
    # @param text [String] the email text content (optional if html or template is passed)
    # @param html [String] the email HTML content (optional if text or template is passed)
    # @param template [Hash]{id:, data:} the template id and template data (optional if HTML or text is passed)
    # @return [Smtp2goResponse] response object
    # send
    def send(sender:, recipients:, subject:, template: {}, text: nil, html: nil)
      template.compact! unless template.nil?

      raise Smtp2goParameterException unless [html, text, template].any?
      raise Smtp2goTemplateException unless verify_template(template)

      payload = {
        api_key: @api_key,
        sender: sender,
        recipients: recipients,
        to: recipients,
        subject: subject,
        text_body: text,
        html_body: html,
        template_id: template[:id] || nil,
        template_data: template[:data] || nil
      }.compact
      submit_to_smtp2go(@send_endpoint, payload: payload)
    end

    def batch(emails)
      payload = {
        api_key: @api_key,
        emails: emails
      }
      submit_to_smtp2go(@batch_endpoint, payload: payload)
    end

    def suppressions
      submit_to_smtp2go(@suppression_endpoint, response_object: false)
    end

    private

    def submit_to_smtp2go(endpoint, payload: nil, response_object: true)
      response = HTTParty.post(
        endpoint,
        body: payload&.to_json,
        headers: @headers
      ).compact
     Smtp2goResponse.new(response)
    end

    def verify_batch_email(text: nil, html: nil, template: {})
      template.compact!
      [html, text, template].any?
    end

    def verify_template(template)
      template.empty? || (TEMPLATE_KEYS - template.keys).empty?
    end
  end

  # Wraps response object with smtp2go specific data
  class Smtp2goResponse
    attr_reader :rate_limit, :response

    def initialize(response)
      @response = response
      @rate_limit = RateLimit.new response.headers if response.respond_to?(:headers)
    end

    # httparty returns JSON by default
    def json
      @response
    end

    def success?
      @response['data']['succeeded'] ? true : false
    end

    def errors
      @response['data']['error']
    end

    def request_id
      @response['request_id']
    end

    def batch_ids
      @batch_ids ||= response['data']
    end

    def raw
      @response
    end

    def status_code
      @response.code
    end
  end

  # Rate limiting class to be attached to response
  class RateLimit
    attr_reader :limit, :remaining, :reset

    def initialize(headers)
      return if headers.nil?

      @limit = headers['x-ratelimit-limit']
      @remaining = headers['x-ratelimit-remaining']
      @reset = headers['x-ratelimit-reset']
    end
  end
end
