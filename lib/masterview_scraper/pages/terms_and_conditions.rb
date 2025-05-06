# frozen_string_literal: true

module MasterviewScraper
  module Pages
    # The first page with the annoying agree button on it
    module TermsAndConditions
      def self.click_agree(page)
        # Click the Agree button on the form
        form = form(page)
        raise "Couldn't find form" if form.nil?

        agreed_field = form.field_with(name: "agreed")
        agreed_field.value = true if agreed_field

        button = button(form)
        raise "Can't find agree button" if button.nil?

        form.submit(button, { "accept-charset" => nil })
      end

      # Check if we're actually on this page
      def self.on_page?(page)
        form = form(page)
        form && button(form)
      end

      def self.form(page)
        return nil unless page.respond_to?(:forms)

        if page.forms.count == 1
          page.forms[0]
        else
          page.form_with(id: "aspnetForm") ||
            page.form_with(id: "frmApplicationMaster") ||
            page.form_with(id: "frmMasterView")
        end
      end

      def self.button(form)
        form.button_with(value: /Agree/i) ||
          form.button_with(id: "agree")
      end
    end
  end
end
