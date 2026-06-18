require "httpx"

module Http
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
               "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
  HEADERS = {
    "User-Agent"      => USER_AGENT,
    "Accept"          => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language" => "en-US,en;q=0.9"
  }.freeze
  TIMEOUT = { connect_timeout: 10, operation_timeout: 30 }.freeze

  class Error < StandardError; end

  def self.client
    @client ||= HTTPX
      .with(headers: HEADERS)
      .with(timeout: TIMEOUT)
      .plugin(:follow_redirects, max_redirects: 5)
  end

  def self.get(url)
    response = client.get(url)
    raise Error, "HTTP #{response.status} for #{url}" unless response.status.between?(200, 299)
    response.body.to_s
  end
end
