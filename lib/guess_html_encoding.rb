require "guess_html_encoding/version"

module GuessHtmlEncoding
  def self.guess(html, headers = nil)
    html = html.dup.force_encoding("ASCII-8BIT")
    headers = headers.dup.force_encoding("ASCII-8BIT") if headers

    out = nil

    (headers || "").split("\n").map {|i| i.split(":")}.each do |k,v|
      if k =~ /Content-Type/i && v =~ /charset=([\w\d-]+);?/i
        out = $1.upcase
      end
    end

    if out.nil? || out.empty? || !Encoding.name_list.include?(out)
      if html =~ /<meta[^>]*HTTP-EQUIV=["']Content-Type["'][^>]*content=["']([^'"]*)["']/i && $1 =~ /charset=([\w\d-]+);?/i
        out = $1.upcase
      end
    end

    if out
      out = "UTF-8" if ["DEFAULT", "UTF8", "UNICODE"].include?(out.upcase)
      out = "CP1251" if out.upcase == "CP-1251"
      out = "ISO-8859-1" if ["LATIN1", "LATIN-1"].include?(out.upcase)
      out = "Windows-1250" if ["WIN-1251", "WIN1251"].include?(out.upcase)
    end

    out
  end

  def self.encode(html, headers = nil)
    encoding = guess(html, (headers || '').gsub(/[\r\n]+/, "\n"))
    html.force_encoding(encoding ? encoding : "UTF-8")
    if html.valid_encoding?
      html
    else
      html.force_encoding('ASCII-8BIT').encode('UTF-8', :undef => :replace, :invalid => :replace)
    end
  end
end
