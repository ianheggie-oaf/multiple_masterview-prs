# frozen_string_literal: true

module MasterviewScraper
  # Utility for getting stuff out of html tables
  module Table
    # TODO: Pages::Index doesn't require the :url so let's try to get rid of it
    def self.extract_table(table, uri)
      headers = header_elements(table).map { |th| th.inner_text.strip }
      row_count = 0
      body_rows(table).map do |tr|
        row_count += 1
        row = tr.search("td").map { |td| td.inner_html.strip }
        # Just skip a row with a different number of columns
        next if row.length != headers.length

        link = tr.at("a")
        raise "Couldn't find link in a table row #{row_count} on #{uri}" if link.nil?

        {
          url: link["href"],
          content: headers.zip(row).to_h
        }
      end.compact
    end

    def self.header_elements(table)
      # If it's actually got a header use that
      if table.at("thead")
        table.at("thead").search("th")
      # Otherwise just use the first row
      else
        table.at("tr").search("td")
      end
    end

    def self.header_row(table)
      # If it's actually got a header use that
      if table.at("thead")
        table.at("thead").at("tr")
      # Otherwise just use the first row
      else
        table.at("tr")
      end
    end

    def self.body_rows(table)
      # If it's actually got a body use that
      if table.at("> tbody")
        table.at("> tbody").search("tr")
      # Otherwise assume the first row is the header and
      # return everything else
      else
        table.search("tr")[1..-1]
      end
    end
  end
end
