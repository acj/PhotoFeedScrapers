require_relative "base"

module Scrapers
  # The Big Picture no longer publishes a usable RSS feed; scrape the hub page
  # and follow links to individual photo essays.
  class BostonGlobeBigPicture < Base
    SOURCE       = "Boston Globe — The Big Picture"
    INDEX_URL    = "https://www.bostonglobe.com/multimedia/photo/big-picture/"
    INDEX_FORMAT = :html
    BASE_URL     = "https://www.bostonglobe.com".freeze

    # Story URLs look like /YYYY/MM/DD/<section>/<slug>/
    STORY_HREF_PATTERN = %r{\A/(\d{4})/(\d{2})/(\d{2})/[^/]+/[^/]+/?\z}.freeze

    PHOTO_FIGURE_SELECTOR  = "figure".freeze
    PHOTO_IMG_SELECTOR     = "img".freeze
    PHOTO_CAPTION_SELECTOR = "figcaption".freeze

    def self.parse_html_index(body)
      doc = Nokogiri::HTML(body)
      seen = {}
      doc.css("a[href]").each do |a|
        href = a["href"].to_s
        m = STORY_HREF_PATTERN.match(href)
        next unless m

        url = "#{BASE_URL}#{href}".sub(%r{/+\z}, "/")
        next if seen.key?(url)

        pub = Time.utc(m[1].to_i, m[2].to_i, m[3].to_i).to_i
        seen[url] = {
          title:    clean(a.text.empty? ? a["title"] : a.text),
          page_url: url,
          pub_date: pub
        }
      end
      seen.values.sort_by { |p| -p[:pub_date] }.first(15)
    end

    def self.extract_photos(post)
      body = Http.get(post[:page_url])
      doc  = Nokogiri::HTML(body)
      base = post[:page_url]

      pub_date  = extract_pub_date(doc) || post[:pub_date]
      headline  = clean(doc.at_css("h1")&.text) || post[:title]

      doc.css(PHOTO_FIGURE_SELECTOR).filter_map do |fig|
        img = fig.at_css(PHOTO_IMG_SELECTOR)
        next nil unless img

        src = best_src(img)
        next nil unless src
        next nil unless src.match?(/\.(jpe?g|png|webp)/i)

        caption = fig.at_css(PHOTO_CAPTION_SELECTOR)&.text
        PhotoFeedItem.new(
          source:    SOURCE,
          title:     headline,
          caption:   clean(caption),
          page_url:  base,
          photo_url: absolute(src, base),
          pub_date:  pub_date
        )
      end
    end

    def self.extract_pub_date(doc)
      str = doc.at_css("meta[itemprop='datePublished']")&.[]("content") ||
            doc.at_css("meta[property='article:published_time']")&.[]("content")
      parse_time(str)
    end
  end
end
