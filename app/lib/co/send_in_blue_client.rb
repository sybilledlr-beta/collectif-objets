# frozen_string_literal: true

# url = require"
module Co
  class SendInBlueClient
    include Singleton

    EMAIL_EVENTS = {
      preserved: %w[delivered requests clicks error].freeze,
      ignored: %w[deferred unsubscribed loadedByProxy].freeze,
      error: %w[bounces hardBounces softBounces spam invalid blocked error].freeze
    }.freeze

    EVENT_STRUCT = Struct.new(:event, :date, :error, :error_reason)
    HOST = "api.sendinblue.com"

    def get_transaction_email_events(message_id)
      get_api_request("/v3/smtp/statistics/events", limit: 20, messageId: message_id).fetch("events", [])
        .map { _1.transform_keys(&:underscore).with_indifferent_access }
        .select { _1[:message_id] == message_id }
        .reject { EMAIL_EVENTS[:ignored].include?(_1[:event]) }
        .map { parse_email_event(_1) }
        .sort_by { _1[:date] }
    end

    def get_transactional_emails(email: nil, message_id: nil)
      filters = { sort: "desc", limit: 20, email:, messageId: message_id }.compact
      get_api_request("/v3/smtp/emails", **filters)["transactionalEmails"]
    end

    def get_transactional_email_uuid(message_id:)
      email = get_transactional_emails(message_id:)&.first
      return nil unless email

      email["uuid"]
    end

    def get_contact(email)
      get_api_request("/v3/contacts/#{email}")
    end

    def create_inbound_email_webhook(url:, domain:, description:)
      post_api_request(
        "/v3/webhooks",
        type: "inbound", events: ["inboundEmailProcessed"],
        url:, domain:, description:
      )
    end

    def list_webhooks
      get_api_request("/v3/webhooks")
    end

    private

    def parse_email_event(raw)
      date = DateTime.parse(raw[:date])
      if EMAIL_EVENTS[:preserved].include?(raw[:event])
        EVENT_STRUCT.new(raw[:event].underscore, date)
      else
        EVENT_STRUCT.new("error", date, raw[:event].underscore, raw[:reason])
      end
    end

    def get_api_request(path, **params)
      JSON.parse(get_api_request_raw(path, **params))
    end

    def get_api_request_raw(path, **params)
      url = URI::HTTPS.build(host: HOST, path:, query: params.to_query)
      request = build_request(url, method: :get)
      http.request(request).read_body
    end

    def post_api_request(path, **params)
      JSON.parse(post_api_request_raw(path, **params))
    end

    def post_api_request_raw(path, **params)
      url = URI::HTTPS.build(host: HOST, path:)
      request = build_request(url, method: :post)
      request.body = params.to_json
      res = http.request(request)
      unless res.code.to_s.starts_with?("2")
        raise "http response #{res.code} - #{res.message} - #{JSON.parse(res.read_body)}"
      end

      res.read_body
    end

    def http
      http = Net::HTTP.new(HOST, 80)
      http.use_ssl = true
      http
    end

    def build_request(url, method: :get)
      klass = { get: Net::HTTP::Get, post: Net::HTTP::Post }[method]
      request = klass.new(url)
      request["accept"] = "application/json"
      request["content-type"] = "application/json"
      request["api-key"] = api_key
      request
    end

    def api_key
      Rails.application.credentials.sendinblue&.api_key
    end
  end
end
