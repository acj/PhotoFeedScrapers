require "logger"
require_relative "store"
require_relative "feed_builder"
require_relative "scrapers/atlantic_in_focus"
require_relative "scrapers/atlantic_viewfinder"
require_relative "scrapers/guardian_photos_of_the_day"
require_relative "scrapers/boston_globe_big_picture"
require_relative "scrapers/nyt_lens"
require_relative "scrapers/reuters_wider_image"

class Runner
  ALL_SCRAPERS = [
    Scrapers::AtlanticInFocus,
    Scrapers::AtlanticViewfinder,
    Scrapers::GuardianPhotosOfTheDay,
    Scrapers::BostonGlobeBigPicture,
    Scrapers::NytLens,
    Scrapers::ReutersWiderImage
  ].freeze

  FEED_LIMIT = 250

  def initialize(db_path:, output_path:, self_url: nil, logger: Logger.new($stdout))
    @db_path     = db_path
    @output_path = output_path
    @self_url    = self_url
    @logger      = logger
  end

  def run
    store = Store.new(@db_path)

    enabled_scrapers.each do |scraper|
      scraper.logger = @logger
      run_one(scraper, store)
    end

    write_feed(store)
  ensure
    store&.close
  end

  private

  def enabled_scrapers
    ALL_SCRAPERS.select { |s| !s.const_defined?(:ENABLED) || s.const_get(:ENABLED) }
  end

  def run_one(scraper, store)
    @logger.info("[#{scraper.source}] scraping…")
    items   = scraper.scrape
    added   = items.sum { |i| store.upsert(i) }
    @logger.info("[#{scraper.source}] #{items.size} items, #{added} new/updated")
  rescue => e
    @logger.error("[#{scraper.source}] failed: #{e.class}: #{e.message}")
  end

  def write_feed(store)
    items = store.recent(FEED_LIMIT)
    xml   = FeedBuilder.build(items, self_url: @self_url)
    FileUtils.mkdir_p(File.dirname(@output_path))
    tmp = "#{@output_path}.tmp"
    File.write(tmp, xml)
    File.rename(tmp, @output_path)
    @logger.info("wrote #{items.size} items to #{@output_path}")
  end
end
