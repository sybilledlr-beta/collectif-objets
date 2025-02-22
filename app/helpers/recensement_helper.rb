# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module RecensementHelper
  Option = Struct.new :value, :label, :badge_color

  # rubocop:disable Metrics/MethodLength
  def localisation_options(recensement)
    [
      Option.new(
        Recensement::LOCALISATION_EDIFICE_INITIAL,
        "L'objet est bien présent dans l'édifice #{recensement.objet.edifice_nom}"
      ),
      Option.new(
        Recensement::LOCALISATION_AUTRE_EDIFICE,
        "L'objet est présent dans un autre édifice"
      ),
      Option.new(
        Recensement::LOCALISATION_ABSENT,
        "L’objet est introuvable, ou bien vous savez qu'il a disparu"
      )
    ]
  end

  def etat_badge_color(etat)
    {
      Recensement::ETAT_BON => "success",
      Recensement::ETAT_MOYEN => "info",
      Recensement::ETAT_MAUVAIS => "new",
      Recensement::ETAT_PERIL => "warning"
    }[etat]
  end

  def etat_sanitaire_options
    Recensement::ETATS.map do |etat|
      Option.new(
        etat,
        t("recensement.etat_sanitaire_choices.#{etat}"),
        etat_badge_color(etat)
      )
    end
  end

  def etat_sanitaire_options_for_select
    etat_sanitaire_options.map { [_1.label, _1.value] }
  end

  def etat_sanitaire_edifice_options
    Recensement::ETATS.map do |etat|
      Option.new(
        etat,
        t("recensement.etat_sanitaire_edifice_choices.#{etat}"),
        etat_badge_color(etat)
      )
    end
  end

  def etat_sanitaire_edifice_options_for_select
    etat_sanitaire_edifice_options.map { [_1.label, _1.value] }
  end

  def etat_sanitaire_badge(value, **html_opts)
    badge(etat_badge_color(value), **html_opts) do
      t("recensement.etat_sanitaire_choices.#{value}")
    end
  end

  def etat_sanitaire_edifice_badge(value, **html_opts)
    badge(etat_badge_color(value), **html_opts) do
      t("recensement.etat_sanitaire_edifice_choices.#{value}")
    end
  end

  alias analyse_etat_sanitaire_badge etat_sanitaire_badge
  alias analyse_etat_sanitaire_edifice_badge etat_sanitaire_edifice_badge

  def securisation_options
    [
      Option.new(
        Recensement::SECURISATION_MAUVAISE,
        t("recensement.securisation_choices.mauvaise"),
        "warning"
      ),
      Option.new(
        Recensement::SECURISATION_CORRECTE,
        t("recensement.securisation_choices.correcte"),
        "success"
      )
    ]
  end

  def securisation_badge(value, **html_opts)
    opt = securisation_options.find { _1.value == value }
    badge(opt.badge_color, **html_opts) { opt.label }
  end
  alias securisation_edifice_badge securisation_badge
  alias analyse_securisation_badge securisation_badge

  def securisation_options_for_select
    securisation_options.map { [_1.label, _1.value] }
  end

  def recensable_options
    [
      Option.new(
        "true",
        "Oui"
      ),
      Option.new(
        "false",
        "Non"
      )
    ]
  end

  # rubocop:enable Metrics/MethodLength

  def analyse_attribute_component(recensement:, form_builder:, recensement_presenter:, attribute_name:)
    original_attribute_name = attribute_name
    if recensement.analysable?
      Conservateurs::AnalyseOverrideEditableComponent.new \
        form_builder:, recensement_presenter:, original_attribute_name:
    else
      Conservateurs::AnalyseOverrideComponent.new \
        recensement:, recensement_presenter:, original_attribute_name:
    end
  end
end
# rubocop:enable Metrics/ModuleLength
