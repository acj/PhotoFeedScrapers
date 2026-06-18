require_relative "base"

module Scrapers
  # Reuters article pages are behind DataDome bot protection, but Reuters
  # publishes a category sitemap that includes per-story lead images and
  # captions. We use that as both the index and the photo source.
  class ReutersWiderImage < Base
    SOURCE       = "Reuters — The Wider Image"
    INDEX_URL    = "https://www.reuters.com/arc/outboundfeeds/sitemap/category/wider-image/?outputType=xml"
    INDEX_FORMAT = :xml

    SITEMAP_NS = {
      "x" => "http://www.sitemaps.org/schemas/sitemap/0.9",
      "i" => "http://www.google.com/schemas/sitemap-image/1.1"
    }.freeze

    def self.scrape
      body = Http.get(INDEX_URL)
      doc  = Nokogiri::XML(body)

      doc.xpath("//x:url", SITEMAP_NS).flat_map do |url|
        page_url = url.at_xpath("x:loc", SITEMAP_NS)&.text
        next [] if page_url.nil? || page_url.empty?

        pub_date = parse_time(url.at_xpath("x:lastmod", SITEMAP_NS)&.text)
        title    = title_from_slug(page_url)

        url.xpath("i:image", SITEMAP_NS).filter_map do |img|
          photo   = img.at_xpath("i:loc",     SITEMAP_NS)&.text
          caption = img.at_xpath("i:caption", SITEMAP_NS)&.text
          next nil if photo.nil? || photo.empty?

          PhotoFeedItem.new(
            source:    SOURCE,
            title:     title,
            caption:   clean(caption),
            page_url:  page_url,
            photo_url: photo,
            pub_date:  pub_date
          )
        end
      end
    end

    def self.title_from_slug(url)
      slug = URI(url).path.split("/").reject(&:empty?).last.to_s
      slug = slug.sub(/-\d{4}-\d{2}-\d{2}\z/, "")
      slug.tr("-", " ").split.map(&:capitalize).join(" ")
    rescue URI::InvalidURIError
      nil
    end
  end
end
