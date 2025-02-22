# frozen_string_literal: true

module Synchronizer
  class ApiClientSql
    include ApiClientConcern

    API_PATH = "data.json"

    QUERY = Struct.new(:table, :select_cols, :join, :where, :group, keyword_init: true)
    OBJETS_QUERY = QUERY.new(
      table: "palissy",
      select_cols: "
          palissy.rowid,
          REF, DENO, CATE, SCLE, DENQ, COM, INSEE, DPT, DOSS, EDIF, EMPL, TICO,
          group_concat(ptmerimee.REF_MERIMEE) as REFS_MERIMEE
      ",
      join: <<~SQL.squish,
        left join palissy_to_merimee ptmerimee on ptmerimee.REF_PALISSY = palissy.REF
      SQL
      where: <<~SQL.squish,
        WHERE "DOSS" = 'dossier individuel'
        and ("MANQUANT" is NULL OR "MANQUANT" NOT IN ('manquant', 'volé'))
        and ("PROT" IS NULL OR "PROT" != 'déclassé')
        and "propriété de l'Etat" not in (select value from json_each([palissy].[STAT]))
        and "propriété de l'Etat (?)" not in (select value from json_each([palissy].[STAT]))
      SQL
      group: "group by palissy.REF"
    )
    EDIFICES_QUERY = QUERY.new(
      table: "merimee",
      select_cols: "REF, INSEE, TICO, PRODUCTEUR",
      join: "INNER JOIN palissy_to_merimee ptm ON merimee.REF = ptm.REF_MERIMEE",
      group: "group by REF, INSEE, TICO, PRODUCTEUR"
    )

    def self.objets(logger:, limit:)
      new(OBJETS_QUERY, logger:, limit:)
    end

    def self.edifices(logger:, limit:)
      new(EDIFICES_QUERY, logger:, limit:)
    end

    def initialize(query, logger:, limit:)
      @query = query
      @logger = logger
      @limit = limit
    end

    def iterate_batches
      create_progress_bar(total_rows)
      @request_number = 1
      api_query { yield _1 }
    end

    def iterate
      iterate_batches { |batch| batch.each { yield _1 } }
    end

    private

    def total_rows
      sql = "select count(*) as c from (select REF from #{@query.table} #{@query.join} #{@query.where} #{@query.group})"
      @logger.info sql
      fetch_and_parse(API_PATH, { sql: })["rows"][0][0]
    end

    def api_query(after_ref: nil)
      sql = get_sql_query(after_ref:)
      @logger.debug sql
      parsed = fetch_and_parse(API_PATH, sql:)
      parsed["rows"] = parsed["rows"].map { parsed["columns"].zip(_1).to_h }
      yield parsed["rows"]
      increment_progress_bar parsed["rows"].count
      trigger_next_query(parsed) { yield _1 }
    end

    def get_sql_query(after_ref: nil)
      offset_clause = after_ref ? "AND #{@query.table}.REF > '#{after_ref}'" : ""
      <<~SQL.squish
        SELECT #{@query.select_cols}
        FROM #{@query.table}
        #{@query.join}
        #{@query.where}
        #{offset_clause}
        #{@query.group}
        ORDER BY #{@query.table}.REF
        LIMIT #{PER_PAGE}
      SQL
    end

    def trigger_next_query(parsed)
      return if parsed["rows"].count < PER_PAGE || limit_reached?

      sleep(0.5)
      @request_number += 1
      api_query(after_ref: parsed["rows"][-1]["REF"]) { yield _1 }
    end
  end
end
