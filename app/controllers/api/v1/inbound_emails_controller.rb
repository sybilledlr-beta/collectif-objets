# frozen_string_literal: true

module Api
  module V1
    class InboundEmailsController < BaseController
      def create
        emails = params["items"].map { parse_email(_1) }
        render json: { emails: }
      end

      private

      def parse_email(item)
        from = item[:From][:Address]
        { from: }
      end
    end
  end
end
