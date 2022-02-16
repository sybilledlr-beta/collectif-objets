# frozen_string_literal: true

class ObjetsController < ApplicationController
  def index
    @filters = {
      commune: params[:commune_code_insee].present? ? Commune.find_by_code_insee(params[:commune_code_insee]) : nil
    }.compact
    @pagy, @objets = pagy(
      Objet
        .displayable
        .where(@filters[:commune] ? { commune_code_insee: @filters[:commune].code_insee } : nil)
        .with_photos_first
    )
  end

  def index_print
    raise unless params[:commune_code_insee].present?

    @commune = Commune.find_by_code_insee(params[:commune_code_insee])
    raise unless @commune.present?

    @objets = Objet.where(commune: @commune)
  end

  def show
    @objet = Objet.find(params[:id])
  end

  def show_by_ref_pop
    @objet = Objet.find_by_ref_pop(params[:ref_pop])
    render :show
  end
end
