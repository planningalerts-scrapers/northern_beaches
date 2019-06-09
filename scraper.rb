require "icon_scraper"

IconScraper.scrape_with_params(
  url: "https://eservices.northernbeaches.nsw.gov.au/ePlanning/live/Public",
  period: "last14days",
  types: ["DevApp"]
) do |record|
  IconScraper.save(record)
end
