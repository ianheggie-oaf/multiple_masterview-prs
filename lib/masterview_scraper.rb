# frozen_string_literal: true

require "masterview_scraper/version"
require "masterview_scraper/pages/detail"
require "masterview_scraper/pages/index"
require "masterview_scraper/pages/terms_and_conditions"
require "masterview_scraper/table"
require "masterview_scraper/authorities"
require "masterview_scraper/get_applications_api"

require "scraperwiki"
require "mechanize"

# Scrape a masterview development application system
module MasterviewScraper
  def self.scrape(authority)
    raise "Unexpected authority: #{authority}" unless AUTHORITIES.key?(authority)

    scrape_period(AUTHORITIES[authority]) do |record|
      yield record
    end
  end

  def self.scrape_and_save(authority)
    scrape(authority) do |record|
      save(record)
    end
  end

  def self.scrape_period(
    url:,
    params: {},
    state: nil,
    use_api: false,
    long_council_reference: false,
    # If this is true get all the information from the detail page. Use this
    # as a stepping stone to adding "decision" and "decision date" which is only
    # available on the detail page
    force_detail: false,
    timeout: nil,
    types: nil,
    # page_size only applies when use_api is true at the moment
    page_size: 100
  )
    if use_api
      scrape_api_period(
        url,
        long_council_reference,
        types,
        force_detail,
        timeout,
        page_size
      ) do |record|
        yield record
      end
    else
      scrape_url(
        url_last_n_days(url, 30, params),
        state,
        force_detail,
        timeout
      ) do |record|
        yield record
      end
    end
  end

  def self.scrape_api_period(
    url, long_council_reference, types,
    force_detail, timeout, page_size = 100
  )
    agent = Mechanize.new
    # We're doing this for every authority because the problem of incomplete certificates
    # is now common enough
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    # On morph.io set the environment variable MORPH_AUSTRALIAN_PROXY to
    # http://morph:password@au.proxy.oaf.org.au:8888 replacing password with
    # the real password.
    # We're using the proxy for every authority because the problem is becoming common
    # enough that it's easier just to use it for everything
    agent.agent.set_proxy(ENV["MORPH_AUSTRALIAN_PROXY"])
    if timeout
      agent.open_timeout = timeout
      agent.read_timeout = timeout
    end

    page = agent.get(url + "/")

    if Pages::TermsAndConditions.on_page?(page)
      MasterviewScraper::Pages::TermsAndConditions.click_agree(page)
    end

    GetApplicationsApi.scrape(
      url: url,
      agent: agent, long_council_reference: long_council_reference, types: types,
      page_size: page_size
    ) do |record|
      if force_detail
        page = begin
                 agent.get(record["info_url"])
               rescue Mechanize::ResponseCodeError
                 nil
               end
        if page.nil?
          puts "PROBLEM LOADING PAGE #{record['info_url']}"
          next
        end
        detail = Pages::Detail.scrape(page)
        # If the detail page is missing just skip this application
        if detail
          yield(
            {
              "council_reference" => record["council_reference"],
              "address" => detail[:address],
              "description" => detail[:description],
              "info_url" => record["info_url"],
              "date_scraped" => Date.today.to_s,
              "date_received" => detail[:date_received]
              # Comment the extra data out until we have moved over every authority over
              # to using the detail page
              # "date_decision": detail[:date_decision],
              # "decision": detail[:decision]
            }
          )
        end
      else
        yield record
      end
    end
  end

  # Set state if the address does not already include the state (e.g. NSW, WA, etc..)
  def self.scrape_url(url, state = nil, force_detail = false,
                      timeout = nil)
    agent = Mechanize.new
    # We're using the proxy for every authority because the problem is becoming common
    # enough that it's easier just to use it for everything
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    # On morph.io set the environment variable MORPH_AUSTRALIAN_PROXY to
    # http://morph:password@au.proxy.oaf.org.au:8888 replacing password with
    # the real password.
    agent.agent.set_proxy(ENV["MORPH_AUSTRALIAN_PROXY"])
    if timeout
      agent.open_timeout = timeout
      agent.read_timeout = timeout
    end

    # Read in a page
    page = agent.get(url)

    if Pages::TermsAndConditions.on_page?(page)
      Pages::TermsAndConditions.click_agree(page)

      # Some (but not all) sites do not redirect back to the original
      # requested url after the terms and conditions page. So,
      # let's just request it again
      page = agent.get(url)
    end

    while page
      Pages::Index.scrape(page) do |record|
        # If index page doesn't have enough information then we need
        # to scrape the detail page
        if force_detail ||
           record[:info_url].nil? ||
           record[:council_reference].nil? ||
           record[:date_received].nil? ||
           record[:description].nil? ||
           record[:address].nil?

          begin
            info_page = agent.get(record[:info_url])
          # Doing this for the benefit of bellingen that
          # appears to be able to fault on detail pages of particular
          # applications
          rescue Mechanize::ResponseCodeError
            puts "WARNING: Skipping application because of server problem"
            next
          end
          detail = Pages::Detail.scrape(info_page)
          record[:info_url] = detail[:info_url]
          # Use the council_reference, date_received and address from the index page whenever we can
          record[:council_reference] = detail[:council_reference] if record[:council_reference].nil?
          record[:date_received] = detail[:date_received] if record[:date_received].nil?
          record[:description] = detail[:description]
          record[:address] = detail[:address] if record[:address].nil?
        end

        record[:address] += ", " + state if state

        yield(
          "info_url" => record[:info_url],
          "council_reference" => record[:council_reference],
          "date_received" => record[:date_received],
          "description" => record[:description],
          "address" => record[:address],
          "date_scraped" => Date.today.to_s
        )
      end
      page = Pages::Index.next(page)
    end
  end

  def self.log(record)
    puts "Saving record " + record["council_reference"] + " - " + record["address"]
  end

  def self.save(record)
    log(record)
    ScraperWiki.save_sqlite(["council_reference"], record)
  end

  def self.url_date_range(base_url, from, to, params)
    url_with_default_params(
      base_url,
      { "1" => from.strftime("%d/%m/%Y"), "2" => to.strftime("%d/%m/%Y") }.merge(params)
    )
  end

  # TODO: Escape params by using activesupport .to_query
  def self.url_with_params(base_url, params)
    base_url + "/default.aspx?" + params.map { |k, v| "#{k}=#{v}" }.join("&")
  end

  def self.url_with_default_params(base_url, params)
    url_with_params(
      base_url,
      { "page" => "found" }.merge(params)
    )
  end

  def self.url_last_n_days(base_url, days, params = {})
    url_date_range(base_url, Date.today - days, Date.today, params)
  end
end
