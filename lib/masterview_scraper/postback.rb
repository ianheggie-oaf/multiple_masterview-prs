# frozen_string_literal: true

module MasterviewScraper
  # Help with handling asp.net doPostBack
  module Postback
    # Implement a click on a link that understands stupid asp.net doPostBack
    def self.click(doc, page)
      js = doc["href"] || doc["onclick"]
      raise "Couldn't find either href or onclick attributes in link on #{page.uri}" if js.nil?

      return if js =~ /return false;/

      # TODO: Just follow the link likes it's a normal link
      unless js =~ /javascript:__doPostBack\('(.*)','(.*)'\)/
        raise "Expected a javascript postback link here: #{js} on #{page.uri}"
      end

      form = page.form_with(id: "aspnetForm")
      form["__EVENTTARGET"] = Regexp.last_match(1)
      form["__EVENTARGUMENT"] = Regexp.last_match(2)
      form.submit
    end
  end
end
