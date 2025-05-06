# frozen_string_literal: true

require "json"

module MasterviewScraper
  # This API endpoint only exists on recent versions of the system
  module GetApplicationsApi
    # Returns applications received in the last 30 days
    def self.scrape(url:, agent:, long_council_reference:,
                    types:, lowercase_api_call:, page_size: 100)
      page_no = 0
      # Start with the assumption that there is at least one records to be returned
      total_records = 1
      start_date = Date.today - 30
      end_date = Date.today

      while total_records > page_no * page_size
        total_records = scrape_page(
          offset: page_no * page_size, limit: page_size, url: url,
          start_date: start_date, end_date: end_date,
          agent: agent, long_council_reference: long_council_reference, types: types,
          lowercase_api_call: lowercase_api_call
        ) do |record|
          yield record
        end
        page_no += 1
      end
    end

    def self.scrape_page(
      offset:, limit:, url:, start_date:, end_date:, agent:, lowercase_api_call:,
      long_council_reference:, types:
    )
      json = {
        "DateFrom" => start_date.strftime("%d/%m/%Y"),
        "DateTo" => end_date.strftime("%d/%m/%Y"),
        "DateType" => "1",
        "RemoveUndeterminedApplications" => false,
        "ShowOutstandingApplications" => false,
        "ShowExhibitedApplications" => false,
        "IncludeDocuments" => false
      }
      json["ApplicationType"] = types.join(",") if types

      path = +"/Application/GetApplications"
      path.downcase! if lowercase_api_call
      page = agent.post(
        url + path,
        "start" => offset,
        "length" => limit,
        "json" => json.to_json
      )

      # Just because it's a JSON API doesn't mean it can't be interrupted with HTML Click Me! :(
      if Pages::TermsAndConditions.on_page?(page)
        begin
          Pages::TermsAndConditions.click_agree(page)
        rescue Mechanize::ResponseCodeError => e
          puts "Ignoring error: #{e} on terms and condition click - its hopefully set the required cookies"
        end
        # Clicking doesn't return you to the original page so we need to ask again
        page = agent.post(
          url + path,
          "start" => offset,
          "length" => limit,
          "json" => json.to_json
        )
      end

      result = JSON.parse(page.body)

      # "data" is only populated sensibly if there are records. So check this first
      if result["recordsTotal"].positive?
        result["data"].each do |application|
          details = application[4].split("<br/>")
          # TODO: Do this properly
          description = details[-1].gsub("<b>", "").gsub("</b>", "").squeeze(" ")
          # If no description then use the application type as the description
          description = application[2] if description.empty?
          yield(
            "council_reference" => long_council_reference ? application[0] : application[1],
            # Only picking out the first address
            "address" => details[0].strip,
            "description" => description,
            "info_url" => (page.uri + "ApplicationDetails/" + application[0]).to_s,
            "date_scraped" => Date.today.to_s,
            "date_received" => Date.strptime(application[3], "%d/%m/%Y").to_s
          )
        end
      end

      # Return the total number of records (not just what's in this page)
      result["recordsTotal"]
    rescue JSON::ParserError => e
      puts "ERROR: #{e} parsing:\n#{page.body}\n" if defined?(page) && ScraperUtils::DebugUtils.verbose?
      raise
    end
  end
end
