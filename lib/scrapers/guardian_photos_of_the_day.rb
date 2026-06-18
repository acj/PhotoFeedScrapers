require_relative "base"

module Scrapers
  class GuardianPhotosOfTheDay < Base
    SOURCE       = "The Guardian — Photos of the Day"
    INDEX_URL    = "https://www.theguardian.com/news/series/ten-best-photographs-of-the-day/rss"
    INDEX_FORMAT = :rss

    PHOTO_FIGURE_SELECTOR  = "figure".freeze
    PHOTO_IMG_SELECTOR     = "img".freeze
    PHOTO_CAPTION_SELECTOR = "figcaption".freeze
    IMAGE_WIDTH            = 1600

    def self.extract_photos(post)
      body = Http.get(post[:page_url])
      doc  = Nokogiri::HTML(body)
      base = post[:page_url]

      doc.css(PHOTO_FIGURE_SELECTOR).filter_map do |fig|
        img = fig.at_css(PHOTO_IMG_SELECTOR)
        next nil unless img

        src = img["src"] || img["data-src"]
        next nil unless src
        next nil unless src.match?(/\.(jpe?g|png|webp)/i)

        caption = build_caption(fig.at_css(PHOTO_CAPTION_SELECTOR))
        next nil if caption.nil? || caption.strip.empty?

        PhotoFeedItem.new(
          source:    SOURCE,
          title:     clean(post[:title]),
          caption:   caption,
          page_url:  base,
          photo_url: upscale(absolute(src, base)),
          pub_date:  post[:pub_date]
        )
      end
    end

    def self.build_caption(figcaption)
      return nil unless figcaption

      location = figcaption.at_css("h2")&.text&.strip
      credit   = figcaption.at_css("small")&.text&.strip

      description_parts = figcaption.children.select(&:text?).map { |n| n.text.strip }.reject(&:empty?)
      description = description_parts.join(" ")

      parts = []
      parts << "#{location} —" if location && !location.empty?
      if description && !description.empty?
        description = description.sub(/\.\s*\z/, "") + "."
        parts << description
      end
      parts << credit if credit && !credit.empty?
      clean(parts.join(" "))
    end

    def self.upscale(url)
      return url unless url
      url.sub(/[?&]width=\d+/, "?width=#{IMAGE_WIDTH}")
    end
  end
end
