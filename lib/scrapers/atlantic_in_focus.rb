require_relative "base"

module Scrapers
  # The Atlantic's "Photography" Atom feed covers In Focus photo essays plus
  # the rest of the Photography channel. Updated daily.
  class AtlanticInFocus < Base
    SOURCE       = "The Atlantic — Photography"
    INDEX_URL    = "https://www.theatlantic.com/feed/photography/"
    INDEX_FORMAT = :atom

    PHOTO_FIGURE_SELECTOR  = "figure".freeze
    PHOTO_IMG_SELECTOR     = "img".freeze
    PHOTO_CAPTION_SELECTOR = "figcaption".freeze

    def self.extract_photos(post)
      body = Http.get(post[:page_url])
      doc  = Nokogiri::HTML(body)
      base = post[:page_url]

      doc.css(PHOTO_FIGURE_SELECTOR).filter_map do |fig|
        img = fig.at_css(PHOTO_IMG_SELECTOR)
        next nil unless img

        src = best_src(img)
        next nil unless src
        next nil unless src.match?(/\.(jpe?g|png|webp)/i)

        caption = fig.at_css(PHOTO_CAPTION_SELECTOR)&.text
        PhotoFeedItem.new(
          source:    SOURCE,
          title:     clean(post[:title]),
          caption:   clean(caption),
          page_url:  base,
          photo_url: absolute(src, base),
          pub_date:  post[:pub_date]
        )
      end
    end
  end
end
