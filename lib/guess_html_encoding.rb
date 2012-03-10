require "guess_html_encoding/version"

# A small and simple library for guessing the encoding of HTML in Ruby 1.9.
module GuessHtmlEncoding
  # Guess the encoding of an HTML string, using HTTP headers if provided.  HTTP headers can be a string or a hash.
  def self.guess(html, headers = nil)
    html = html.dup.force_encoding("ASCII-8BIT")
    out = nil

    if headers
      headers = headers.map {|k, v| "#{k}: #{v}" }.join("\n") if headers.is_a?(Hash)
      headers = headers.dup.force_encoding("ASCII-8BIT")
      headers.split("\n").map {|i| i.split(":")}.each do |k,v|
        if k =~ /Content-Type/i && v =~ /charset=([\w\d-]+);?/i
          out = $1.upcase
          break
        end
      end
    end

    if out.nil? || out.empty? || !encoding_loaded?(out)
      if html =~ /<meta[^>]*HTTP-EQUIV=["']Content-Type["'][^>]*content=["']([^'"]*)["']/i && $1 =~ /charset=([\w\d-]+);?/i
        out = $1.upcase
      end
    end

    # Translate encodings with other names.
    if out
      out = "UTF-8" if ["DEFAULT", "UTF8", "UNICODE"].include?(out.upcase)
      out = "CP1251" if out.upcase == "CP-1251"
      out = "ISO-8859-1" if ["LATIN1", "LATIN-1"].include?(out.upcase)
      out = "Windows-1250" if ["WIN-1251", "WIN1251"].include?(out.upcase)
    end

    out
  end

  # Force an HTML string into a guessed encoding.
  def self.encode(html, headers = nil)
    encoding = guess(html, (headers || '').gsub(/[\r\n]+/, "\n"))
    html.force_encoding(encoding_loaded?(encoding) ? encoding : "UTF-8")
    if html.valid_encoding?
      html
    else
      html.force_encoding('ASCII-8BIT').encode('UTF-8', :undef => :replace, :invalid => :replace)
    end
  end

  # Is this encoding loaded?
  def self.encoding_loaded?(encoding)
    Encoding.name_list.include? encoding
  end
end
