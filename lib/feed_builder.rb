require "time"
require "cgi"

class FeedBuilder
  TITLE       = "Photo Feeds"
  DESCRIPTION = "Combined feed of recent photo essays from The Atlantic, The Guardian, " \
                "The Boston Globe, NYT, and Reuters."
  LINK        = "https://github.com/acj/PhotoFeedScrapers"

  def self.build(items, self_url: nil)
    now_rfc822 = Time.now.rfc822

    <<~RSS
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/">
        <channel>
          <title>#{esc(TITLE)}</title>
          <link>#{esc(LINK)}</link>
          <description>#{esc(DESCRIPTION)}</description>
          <lastBuildDate>#{now_rfc822}</lastBuildDate>
          <generator>PhotoFeedScrapers</generator>
          #{self_url ? "<atom:link href=\"#{esc(self_url)}\" rel=\"self\" type=\"application/rss+xml\" />" : ""}
      #{items.map { |i| item_xml(i) }.join("\n")}
        </channel>
      </rss>
    RSS
  end

  def self.item_xml(i)
    title    = i["title"] || "(untitled)"
    source   = i["source"]
    caption  = i["caption"].to_s
    photo    = i["photo_url"]
    page     = i["page_url"]
    pub_ts   = i["pub_date"] || i["first_seen_at"]
    pub_date = Time.at(pub_ts).rfc822

    description_html = <<~HTML.strip
      <p><a href="#{esc(page)}"><img src="#{esc(photo)}" alt="#{esc(title)}" /></a></p>
      <p>#{esc(caption)}</p>
      <p><em>Source: #{esc(source)}</em></p>
    HTML

    <<~ITEM.chomp
          <item>
            <title>#{esc("[#{source}] #{title}")}</title>
            <link>#{esc(page)}</link>
            <guid isPermaLink="false">#{esc(photo)}</guid>
            <pubDate>#{pub_date}</pubDate>
            <source url="#{esc(page)}">#{esc(source)}</source>
            <media:content url="#{esc(photo)}" medium="image" />
            <description>#{esc(description_html)}</description>
          </item>
    ITEM
  end

  def self.esc(str)
    CGI.escapeHTML(str.to_s)
  end
end
