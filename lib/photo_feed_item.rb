PhotoFeedItem = Struct.new(
  :source,
  :title,
  :caption,
  :page_url,
  :photo_url,
  :pub_date,
  keyword_init: true
) do
  def valid?
    photo_url && !photo_url.empty? && page_url && !page_url.empty?
  end
end
