require_relative "base"

module Scrapers
  # NYT Lens still ships an RSS feed (with slow cadence). Article pages are
  # behind a bot wall, so we build feed items directly from the RSS media tags.
  class NytLens < Base
    SOURCE       = "NYT — Lens"
    INDEX_URL    = "https://rss.nytimes.com/services/xml/rss/nyt/Lens.xml"
    INDEX_FORMAT = :rss

    def self.scrape
      body = Http.get(INDEX_URL)
      doc  = Nokogiri::XML(body)
      doc.remove_namespaces!

      doc.css("channel > item").filter_map do |item|
        link    = item.at_css("link")&.text&.strip
        next nil if link.nil? || link.empty?

        media = item.xpath('.//*[local-name()="content"]').find { |m| m["url"] }
        photo = media&.[]("url")
        next nil unless photo

        title = clean(item.at_css("title")&.text)
        desc  = clean(item.at_css("description")&.text)
        PhotoFeedItem.new(
          source:    SOURCE,
          title:     title,
          caption:   desc,
          page_url:  link,
          photo_url: photo,
          pub_date:  parse_time(item.at_css("pubDate")&.text)
        )
      end
    end
  end
end
