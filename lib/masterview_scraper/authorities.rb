# frozen_string_literal: true

module MasterviewScraper
  AUTHORITIES = {
    # Authorities are in alphabetical order so that they're easier to find in this long list
    # When adding a new authority make sure to keep the alphabetical ordering
    albury: {
      url: "https://eservice.alburycity.nsw.gov.au/ApplicationTracker",
      use_api: true,
      force_detail: true
    },
    ballina: {
      url: "https://da.ballina.nsw.gov.au",
      use_api: true
    },
    bega_valley: {
      url: "https://datracker.begavalley.nsw.gov.au",
      use_api: true
    },
    bogan: {
      url: "https://datracker.bogan.nsw.gov.au:81",
      use_api: true,
      force_detail: true
    },
    broken_hill: {
      url: "http://datracker.brokenhill.nsw.gov.au",
      use_api: true
    },
    bundaberg: {
      url: "https://da.bundaberg.qld.gov.au",
      use_api: true,
      force_detail: true
    },
    burwood: {
      url: "https://datracker.burwood.nsw.gov.au",
      use_api: true
    },
    byron: {
      url: "https://datracker.byron.nsw.gov.au/masterviewui-external",
      use_api: true,
      lowercase_api_call: true,
      page_size: 10,
      force_detail: true
    },
    cessnock: {
      url: "https://datracker.cessnock.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    dubbo: {
      url: "https://planning.dubbo.nsw.gov.au/",
      use_api: true
    },
    fairfield: {
      url: "https://openaccess.fairfieldcity.nsw.gov.au/OpenAccess/Modules/Applicationmaster",
      params: { "4a" => 10, "6" => "F" },
      force_detail: true,
      state: "NSW"
    },
    griffith: {
      url: "https://datracking.griffith.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    gunnedah: {
      url: "http://datracking.gunnedah.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    gympie: {
      url: "https://daonline.gympie.qld.gov.au",
      use_api: true,
      force_detail: true
    },
    lismore: {
      url: "https://tracker.lismore.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    maranoa: {
      url: "http://pdonline.maranoa.qld.gov.au",
      use_api: true,
      force_detail: true
    },
    muswellbrook: {
      url: "https://datracker.muswellbrook.nsw.gov.au",
      use_api: true
    },
    port_macquarie_hastings: {
      url: "https://datracker.pmhc.nsw.gov.au",
      use_api: true,
      force_detail: true
    },
    port_stephens: {
      url: "https://datracker.portstephens.nsw.gov.au",
      use_api: true,
      long_council_reference: true,
      types: [16, 9, 25],
      force_detail: true
    },
    shoalhaven: {
      url: "https://www3.shoalhaven.nsw.gov.au/masterviewUI/modules/ApplicationMaster",
      params: {
        "4a" => "25,13,72,60,58,56",
        "6" => "F"
      },
      state: "NSW",
      force_detail: true
    },
    singleton: {
      url: "https://datracker.singleton.nsw.gov.au:444",
      use_api: true,
      force_detail: true
    },
    strathfield: {
      url: "https://datracker.strathfield.nsw.gov.au",
      use_api: true
    },
    upper_hunter: {
      url: "http://onlineservices.upperhunter.nsw.gov.au",
      use_api: true
    }
  }.freeze
end
