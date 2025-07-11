# frozen_string_literal: true

require "timecop"
require "fileutils"
require_relative "../scraper"

RSpec.describe Scraper do
# Authorities that use bot protection (reCAPTCHA, Cloudflare, etc.) on detail pages (info_url)
  AUTHORITIES_WITH_BOT_PROTECTION = %i[
  ].freeze

  describe ".run" do
    def fetch_url_with_redirects(url)
      agent = Mechanize.new
      page = agent.get(url)
      if MasterviewScraper::Pages::TermsAndConditions.on_page?(page)
        puts "Agreeing to terms and conditions for #{url}"
        MasterviewScraper::Pages::TermsAndConditions.click_agree(page)
        page = agent.get(url)
      end
      page
    end

    def test_run(authority)
      ScraperWiki.close_sqlite
      FileUtils.rm_f("data.sqlite")

      VCR.use_cassette(authority) do
        date = Date.new(2025, 4, 15)
        Timecop.freeze(date) do
          Scraper.run([authority])
        end
      end

      expected = if File.exist?("spec/expected/#{authority}.yml")
                   YAML.safe_load(File.read("spec/expected/#{authority}.yml"))
                 else
                   []
                 end
      results = ScraperWiki.select("* from data order by council_reference")

      ScraperWiki.close_sqlite

      if results != expected
        # Overwrite expected so that we can compare with version control
        # (and maybe commit if it is correct)
        File.open("spec/expected/#{authority}.yml", "w") do |f|
          f.write(results.to_yaml)
        end
      end

      expect(results).to eq expected

      if results.any?
        ScraperUtils::SpecSupport.validate_addresses_are_geocodable!(results, percentage: 40, variation: 3)

        ScraperUtils::SpecSupport.validate_descriptions_are_reasonable!(results, percentage: 30, variation: 3)

        global_info_url = Scraper::AUTHORITIES[authority][:info_url]
        bot_check_expected = AUTHORITIES_WITH_BOT_PROTECTION.include?(authority)

        unless ENV['DISABLE_INFO_URL_CHECK']
          if global_info_url
            ScraperUtils::SpecSupport.validate_uses_one_valid_info_url!(results, global_info_url, bot_check_expected: bot_check_expected) do |url|
              fetch_url_with_redirects(url)
            end
          else
            ScraperUtils::SpecSupport.validate_info_urls_have_expected_details!(results, percentage: 70, variation: 3, bot_check_expected: bot_check_expected) do |url|
              fetch_url_with_redirects(url)
            end
          end
        end
      end
    end

    Scraper.selected_authorities.each do |authority|
      it authority do
        test_run(authority)
      end
    end
  end
end
