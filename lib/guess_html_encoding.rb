require "guess_html_encoding/version"

# A small and simple library for guessing the encoding of HTML in Ruby 1.9.
module GuessHtmlEncoding
  # Guess the encoding of an HTML string, using HTTP headers if provided.  HTTP headers can be a string or a hash.
  def self.guess(html, headers = nil)
    html = html.to_s.dup.force_encoding("ASCII-8BIT")
    out = nil

    if headers
      headers = headers.map {|k, v| "#{k}: #{v}" }.join("\n") if headers.is_a?(Hash)
      headers = headers.dup.force_encoding("ASCII-8BIT")
      headers.gsub(/[\r\n]+/, "\n").split("\n").map {|i| i.split(":")}.each do |k,v|
        if k =~ /Content-Type/i && v =~ /charset=([\w\d-]+);?/i
          out = $1.upcase
          break
        end
      end
    end

    if out.nil? || out.empty? || !encoding_loaded?(out)

      out = HTMLScanner.new(html[0,2500]).encoding || out

      out.upcase! unless out.nil?
    end

    # Translate encodings with other names.
    if out
      out = "UTF-8" if %w[DEFAULT UTF8 UNICODE].include?(out)
      out = "CP1251" if out == "CP-1251"
      out = "ISO-8859-1" if %w[LATIN1 LATIN-1].include?(out)
      out = "WINDOWS-1250" if %w[WIN-1251 WIN1251].include?(out)
      out = "GB18030" if %w[GB2312 GB18030].include?(out) 
    end

    out
  end

  # Force an HTML string into a guessed encoding.
  def self.encode(html, headers = nil)
    html_copy = html.to_s.dup
    encoding = guess(html_copy, headers)
    html_copy.force_encoding(encoding_loaded?(encoding) ? encoding : "UTF-8")
    if html_copy.valid_encoding?
      html_copy
    else
      html_copy.force_encoding('ASCII-8BIT').encode('UTF-8', :undef => :replace, :invalid => :replace)
    end
  end

  # Is this encoding loaded?
  def self.encoding_loaded?(encoding)
    !!Encoding.find(encoding) rescue nil
  end

  class HTMLScanner

    def initialize(html)
      @html = html
    end

    # Returns the encoding sniffed from the content of an HTML page, as determined using an 
    # implemention of the algorithm to 'prescan a byte stream to determine its encoding', as
    # specified by the HTML specification: 
    # http://www.w3.org/html/wg/drafts/html/master/syntax.html#prescan-a-byte-stream-to-determine-its-encoding
    def encoding

      position = 0
      charset = nil
      length = @html.length

      done = false

      while position < length && !done

        # First look for a standard HTML comment (ie <!-- blah -->)
        if @html[position, 4] == '<!--'

          position += 2

          position += (@html[position, length].index('-->') || length)

        # Then look for the start of a meta tag
        elsif  @html[position, 6] =~ /\A\<meta[\s\/]/i

          charset, position_increment = charset_from_meta(@html[position + 5, length])

          break if charset

          position += position_increment

        # Then look for <! or </ or <?
        elsif @html[position, 2] =~ /\A\<[\!\/\?]/

          # Advance position to the first > that appears next in string, or end
          position += @html[position, length].index('>') || length

        else
          # Do nothing. (This is just here to make the algorithm easier to follow)
        end

        # Advance position to next character
        position += 1
      end

      charset
    end

    private


    # Given a string which starts with the space or slash following a `<meta`, 
    # look for a charset and returns it along with the position of the next
    # character following the closing `>` character
    def charset_from_meta(string)

      position = 0
      attribute_list = {}
      got_pragma = false
      need_pragma = nil
      charset = nil
      length = string.length

      while position < length

        attribute, position_increment = attribute(string[position, length])
        
        position += position_increment.to_i

        if attribute == nil

          break

        elsif attribute_list[attribute[:attribute_name]]

          # Do nothing
        
        else

          # found a new attribute. Add it to the list
          attribute_list[attribute[:attribute_name]] = attribute[:attribute_value]

          if attribute[:attribute_name] == 'http-equiv'

            got_pragma = true

          elsif attribute[:attribute_name] == 'content'

            content_charset = charset_from_meta_content(attribute[:attribute_value])

            if content_charset && charset == nil
              charset = content_charset
              need_pragma = true
            end

          elsif attribute[:attribute_name] == 'charset'

            charset = attribute[:attribute_value]
            need_pragma = false

          end

        end

      end

      if need_pragma == nil || (need_pragma == true && got_pragma == false)
        [nil, position]
      else
        [charset, position]
      end
      
    end

    # Given a string representing the 'content' attribute value of a meta tag
    # with an `http-equiv` attribute, returns the charset specified within that
    # value, or nil.
    def charset_from_meta_content(string)

      charset_match = string.match(/charset\s*\=\s*(.+)/i)

      if charset_match

        charset_value = charset_match[1]

        charset_value[/\A\"(.*)\"/, 1] ||
        charset_value[/\A\'(.*)\'/, 1] ||
        charset_value[/(.*)[\s;]/, 1] ||
        charset_value[/(.*)/, 1]
      else
        nil
      end

    end

    # Given a string, returns the first attribute in the sting (as a hash), and
    # the position of the next character in the string
    def attribute(string)

      attribute_name = ""
      attribute_value = ""

      length = string.length
      position = 0

      return [nil, nil] if length == 0 

      while position < (length)

        # If character matches 0x09 (ASCII TAB), 0x0A (ASCII LF), 0x0C (ASCII FF), 0x0D (ASCII CR), 0x20 (ASCII space), or 0x2F (ASCII /) then advance position
        if string[position] =~ /[\u{09}\u{0A}\u{0C}\u{0D}\u{20}\u{2f}]/
          
          position += 1
        
        elsif string[position] == '>'

          attribute_name = nil
          break

        else

          while position < length
          
            if string[position] == '=' && attribute_name != ''

              attribute_value, position_increment = attribute_value(string[position + 1, length])

              position += position_increment + 1

              break

            elsif string[position] =~ /[\>\/]/
              
              break
            
            elsif string[position] =~ /[A-Z]/

              attribute_name += string[position].downcase
              position += 1

            else
              attribute_name += string[position]
              position += 1
            end

          end

          break

        end

      end

      if attribute_name
        [{attribute_name: attribute_name, attribute_value: attribute_value}, position]
      else
        [nil, position]
      end

    end

    # Given a string, this returns the attribute value from the start of the string,
    # and the position of the following character in the string
    def attribute_value(string)

      attribute_value = ''
      position = 0
      length = string.length

      while position < length
      
        # x09 (ASCII TAB), 0x0A (ASCII LF), 0x0C (ASCII FF), 0x0D (ASCII CR), or 0x20 (ASCII space) then advance position to the next byte, then, repeat this step.
        if string[position] =~ /[\u{09}\u{0A}\u{0C}\u{0D}\u{20}]/
            
          position += 1

        elsif string[position] =~ /['"]/

          attribute_value, position = quoted_value(string[position, length])
          break

        elsif string[position] == '>'
          position += 1
          break

        else
          attribute_value, position = unquoted_value(string[position, length])
          break
        end
      end

      [attribute_value, position]
    end

    # Given a string, at the start of which is quoted attribute value, returns
    # that attribute value, and the position of the next character in the string
    # (following the second matching quote mark)
    def quoted_value(string)

      attribute_value = ""
      quote_type = string[0]
      position = 1
      length = string.length

      while position < length

        if string[position] == quote_type
          position += 1
          break
        else
          attribute_value += downcase_A_to_Z_only(string[position])
          position += 1
        end

      end

      [attribute_value, position]
    end

    # Given a string, at the start of which is an unquoted attribute value, returns
    # that attribute value, and the position of the next character in the string
    def unquoted_value(string)
      downcased_value = downcase_A_to_Z_only(string[/\A[^\t\u{0A}\u{0C}\u{0D}\u{20}\>]*/])
      [downcased_value, downcased_value.length]
    end

    # Downcases the A-Z characters only (eg not É -> é)
    def downcase_A_to_Z_only(string)
      string.gsub(/([A-Z])/) { |match| match.downcase }
    end

  end
end
