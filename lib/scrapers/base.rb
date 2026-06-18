require "nokogiri"
require "cgi"
require "time"
require_relative "../http"
require_relative "../photo_feed_item"

module Scrapers
  class Base
    SOURCE       = nil
    INDEX_URL    = nil
    INDEX_FORMAT = :rss # :rss or :html

    def self.source       = self::SOURCE
    def self.index_url    = self::INDEX_URL
    def self.index_format = self::INDEX_FORMAT

    def self.logger=(l)
      @logger = l
    end

    def self.logger
      @logger ||= Logger.new($stdout)
    end

    # Returns Array<PhotoFeedItem>
    def self.scrape
      posts = fetch_index
      posts.flat_map do |post|
        sleep 0.5
        extract_photos(post)
      rescue => e
        logger.warn("[#{source}] post failed #{post[:page_url]}: #{e.class}: #{e.message}")
        []
      end.select(&:valid?)
    end

    def self.fetch_index
      body = Http.get(index_url)
      case index_format
      when :rss, :atom then parse_xml_index(body)
      when :html       then parse_html_index(body)
      else raise "unknown index_format #{index_format}"
      end
    end

    # Handles both RSS (channel/item) and Atom (feed/entry).
    def self.parse_xml_index(body)
      doc = Nokogiri::XML(body)
      doc.remove_namespaces!

      items = doc.css("channel > item")
      return items.map { |i| rss_item_to_hash(i) } if items.any?

      doc.css("feed > entry").map { |e| atom_entry_to_hash(e) }
    end

    def self.rss_item_to_hash(item)
      {
        title:    item.at_css("title")&.text&.strip,
        page_url: item.at_css("link")&.text&.strip,
        pub_date: parse_time(item.at_css("pubDate")&.text)
      }
    end

    def self.atom_entry_to_hash(entry)
      link = entry.css("link").find { |l| l["rel"].nil? || l["rel"] == "alternate" }
      {
        title:    entry.at_css("title")&.text&.strip,
        page_url: link&.[]("href")&.strip,
        pub_date: parse_time(entry.at_css("updated")&.text || entry.at_css("published")&.text)
      }
    end

    # Subclasses using HTML indexes override this.
    def self.parse_html_index(_body)
      raise NotImplementedError
    end

    # Subclasses implement this: given a post hash, fetch the page and return
    # an Array<PhotoFeedItem>.
    def self.extract_photos(_post)
      raise NotImplementedError
    end

    def self.parse_time(str)
      return nil if str.nil? || str.empty?
      Time.parse(str).to_i
    rescue ArgumentError
      nil
    end

    def self.clean(text)
      return nil if text.nil?
      # Decode HTML entities (e.g. "&#39;", "&amp;") that survive source parsing,
      # often because the upstream markup double-encoded them, then normalize
      # whitespace.
      CGI.unescapeHTML(text).gsub(/\s+/, " ").strip
    end

    def self.absolute(url, base)
      return nil if url.nil? || url.empty?
      URI.join(base, url).to_s
    rescue URI::InvalidURIError
      url
    end

    # Pick the widest image from a srcset attribute, falling back to src.
    def self.best_src(img)
      srcset = img["srcset"] || img["data-srcset"]
      if srcset && !srcset.empty?
        candidates = srcset.split(",").filter_map do |entry|
          parts = entry.strip.split(/\s+/)
          next nil if parts.size < 2
          w = parts[1].to_i
          [parts[0], w]
        end
        best = candidates.max_by { |_, w| w }
        return best[0] if best
      end
      img["data-src"] || img["src"]
    end
  end
end
