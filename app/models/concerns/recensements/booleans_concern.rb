# frozen_string_literal: true

require "active_support/concern"

module Recensements
  module BooleansConcern
    extend ActiveSupport::Concern

    def absent?
      localisation == Recensement::LOCALISATION_ABSENT
    end

    def autre_edifice?
      localisation == Recensement::LOCALISATION_AUTRE_EDIFICE
    end

    def edifice_initial?
      localisation == Recensement::LOCALISATION_EDIFICE_INITIAL
    end

    def missing_photos?
      recensable? && (edifice_initial? || autre_edifice?) && photos.empty?
    end

    def en_peril?
      [analyse_etat_sanitaire, etat_sanitaire].compact.first == Recensement::ETAT_PERIL
    end

    def en_mauvais_etat?
      [analyse_etat_sanitaire, etat_sanitaire].compact.first == Recensement::ETAT_MAUVAIS
    end

    def prioritaire?
      en_mauvais_etat? || en_peril? || absent?
    end

    def analysable?
      commune.completed?
    end

    def first?
      commune.recensements.empty?
    end
  end
end
