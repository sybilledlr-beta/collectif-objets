# frozen_string_literal: true

require "rails_helper"

RSpec.describe Campaigns::CronJob, type: :job do
  describe "for planned campaigns" do
    let!(:campaign1) { create(:campaign, status: "planned", date_lancement: Date.new(2031, 6, 10)) }
    let!(:campaign2) { create(:campaign, status: "planned", date_lancement: Date.new(2031, 4, 10)) }
    let!(:campaign3) { create(:campaign, status: "planned", date_lancement: Date.new(2031, 5, 9)) }
    let!(:campaign4) { create(:campaign, status: "planned", date_lancement: Date.new(2031, 7, 10)) }

    it "should start only planned campaign with lancement date in the past" do
      expect(Campaigns::RunCampaignJob).not_to receive(:perform_inline).with(campaign1.id)
      expect(Campaigns::RunCampaignJob).to receive(:perform_inline).with(campaign2.id)
      expect(Campaigns::RunCampaignJob).to receive(:perform_inline).with(campaign3.id)
      expect(Campaigns::RunCampaignJob).not_to receive(:perform_inline).with(campaign4.id)

      Campaigns::CronJob.new.perform(Date.new(2031, 5, 15))

      expect(campaign1.reload.status).to eq("planned")
      expect(campaign2.reload.status).to eq("ongoing")
      expect(campaign3.reload.status).to eq("ongoing")
      expect(campaign4.reload.status).to eq("planned")
    end
  end

  describe "for ongoing campaigns" do
    let!(:campaign1) do
      create(:campaign, status: "draft", date_lancement: Date.new(2031, 3, 10), date_fin: Date.new(2031, 6, 2))
    end
    let!(:campaign2) do
      create(:campaign, status: "ongoing", date_lancement: Date.new(2031, 3, 10), date_fin: Date.new(2031, 6, 2))
    end
    let!(:campaign3) do
      create(:campaign, status: "ongoing", date_lancement: Date.new(2031, 3, 10), date_fin: Date.new(2031, 5, 15))
    end
    let!(:campaign4) do
      create(:campaign, status: "ongoing", date_lancement: Date.new(2031, 3, 10), date_fin: Date.new(2031, 6, 2))
    end
    let!(:campaign5) do
      create(:campaign, status: "ongoing", date_lancement: Date.new(2031, 3, 10), date_fin: Date.new(2031, 5, 1))
    end

    it "should enqueue ongoing campaigns only" do
      expect(Campaigns::RunCampaignJob).not_to receive(:perform_inline).with(campaign1.id)
      expect(Campaigns::RunCampaignJob).to receive(:perform_inline).with(campaign2.id)
      expect(Campaigns::RunCampaignJob).to receive(:perform_inline).with(campaign3.id)
      expect(Campaigns::RunCampaignJob).to receive(:perform_inline).with(campaign4.id)
      expect(Campaigns::RunCampaignJob).to receive(:perform_inline).with(campaign5.id)

      Campaigns::CronJob.new.perform(Date.new(2031, 5, 15))

      expect(campaign1.reload.status).to eq("draft")
      expect(campaign2.reload.status).to eq("ongoing")
      expect(campaign3.reload.status).to eq("ongoing") # still ongoing because date_fin = today
      expect(campaign4.reload.status).to eq("ongoing")
      expect(campaign5.reload.status).to eq("finished") # finished because date_fin < today
    end
  end
end
