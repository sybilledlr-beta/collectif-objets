# frozen_string_literal: true

module Synchronizer
  class SynchronizeObjetsJob
    include Sidekiq::Job

    def initialize
      @counters = Hash.new(0)
    end

    def perform(params = {})
      @logfile = File.open("tmp/synchronize-objets-#{timestamp}.log", "a+")
      limit = params.with_indifferent_access[:limit]
      @dry_run = params.with_indifferent_access["dry_run"]
      @interactive = params.with_indifferent_access["interactive"]
      ApiClientSql.objets(logger:, limit:).iterate_batches { synchronize_rows(_1) }
      close
    end

    private

    def synchronize_rows(rows)
      batch = ObjetRevisionsBatch.from_rows(rows)
      batch.revisions_by_action.each do |action, revisions|
        @counters[action] += revisions.count
        revisions.each { synchronize_revision(_1) }
      end
    end

    def synchronize_revision(revision)
      @logfile.puts(revision.log_message) if revision.log_message.present?
      revision.objet.save! if save_revision?(revision)
    end

    def close
      @logfile.puts "counters: #{@counters}"
      @logfile.close
    end

    def timestamp
      Time.zone.now.strftime("%Y_%m_%d_%HH%M")
    end

    def save_revision?(revision)
      return false if @dry_run

      return true if revision.save?

      return false unless @interactive

      return false unless revision.action.to_s.ends_with?("_invalid")

      chomp_save_revision?(revision)
    end

    # rubocop:disable Rails/Output
    def chomp_save_revision?(revision)
      puts "\n----\n#{revision.log_message}\n----"
      response = nil
      while response.nil?
        puts "voulez-vous forcer la sauvegarde de cet objet ? 'oui' : 'non'"
        raw = gets.chomp
        response = false if raw == "non"
        response = true if raw == "oui"
      end
      response
    end
  end
  # rubocop:enable Rails/Output
end
