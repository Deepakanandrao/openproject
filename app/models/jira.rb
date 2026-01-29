class Jira < ApplicationRecord
  validate :url_must_be_http_or_https

  private

  def url_must_be_http_or_https
    return if url.blank?

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      errors.add(:url, :invalid_protocol)
    end
  rescue URI::InvalidURIError
    errors.add(:url, :invalid)
  end
end
