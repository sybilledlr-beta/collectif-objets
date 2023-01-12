# frozen_string_literal: true

puts Co::SendInBlueClient.instance.list_webhooks

puts Co::SendInBlueClient.instance.create_inbound_email_webhook(
  url: "https://collectifobjets-mail-inbound.loophole.site",
  domain: "reponse-loophole.collectifobjets.org",
  description: "Debug inbound email webhook tunneled to localhost"
)
