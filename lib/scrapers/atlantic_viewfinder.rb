require_relative "atlantic_in_focus"

module Scrapers
  # The Atlantic's monthly "Viewfinder" magazine column. Article pages share
  # the figure/img/figcaption layout used by the Photography channel, so we
  # inherit AtlanticInFocus#extract_photos.
  class AtlanticViewfinder < AtlanticInFocus
    SOURCE       = "The Atlantic — Viewfinder"
    INDEX_URL    = "https://www.theatlantic.com/feed/category/viewfinder/"
    INDEX_FORMAT = :atom
  end
end
