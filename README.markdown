# GuessHTMLEncoding

GuessHTMLEncoding is a simple library to guess HTML encodings in Ruby 1.9.  It considers HTTP headers and META tags.

# Install

    (sudo) gem install guess_html_encoding

# Usage

GuessHTMLEncoding can guess the encoding of an HTML file based on the http-equiv content-type:

    require 'rubygems'
    require 'guess_html_encoding'

    guess = GuessHtmlEncoding.guess(<<-HTML)
      <html>
        <head>
          <meta http-equiv="content-type" content="text/html; charset=LATIN1">
        </head>
        <body>
          <div>hi!</div>
        </body>
      </html>
    HTML
    guess.should == "ISO-8859-1"

You can also give it HTTP headers to guess from, which it will prefer, both as a string or as a hash:

    guess = GuessHtmlEncoding.guess("<html><body><div>hi!</div></body></html>",
                                    "Hello: world\nContent-Type: text/html; charset=LATIN1\nFoo: bar")
    guess.should == "ISO-8859-1"

    guess = GuessHtmlEncoding.guess("<html><body><div>hi!</div></body></html>",
                                    {"Hello" => "world", "Content-Type" => "text/html; charset=LATIN1", "Foo" => "bar"})
    guess.should == "ISO-8859-1"

It's likely that you want to force the encoding of the given HTML into the guessed encoding.  This is easy to do:

    data = "<html><head><meta http-equiv='content-type' content='text/html; charset=utf8;'></head><body><div>hi!♥</div></body></html>"
    encoded = GuessHtmlEncoding.encode(data)
    encoded.encoding.to_s.should == "UTF-8"

If an encoding cannot be guessed, or Ruby doesn't understand it, UTF-8 will be used and unknown characters will be ignored.

# Pull requests welcome!