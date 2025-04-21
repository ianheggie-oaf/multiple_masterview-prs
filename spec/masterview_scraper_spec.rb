# frozen_string_literal: true

require "timecop"

RSpec.describe MasterviewScraper do
  it "has a version number" do
    expect(MasterviewScraper::VERSION).not_to be nil
  end
end
