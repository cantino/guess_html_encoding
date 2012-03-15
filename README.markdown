# GuessHtmlEncoding

GuessHtmlEncoding is a simple library to guess the HTML encodings in Ruby 1.9.  See the specs for a complete rundown.

# Usage

It guesses from the http content type:

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

You can also give it HTTP headers to guess from, both as a string or as a hash:

    guess = GuessHtmlEncoding.guess("<html><body><div>hi!</div></body></html>",
                                    "Hello: world\nContent-Type: text/html; charset=LATIN1\nFoo: bar")
    guess.should == "ISO-8859-1"

    guess = GuessHtmlEncoding.guess("<html><body><div>hi!</div></body></html>",
                                    {"Hello" => "world", "Content-Type" => "text/html; charset=LATIN1", "Foo" => "bar"})
    guess.should == "ISO-8859-1"

You can also directly encode the text based on the guess:

    data = "<html><head><meta http-equiv='content-type' content='text/html; charset=utf8;'></head><body><div>hi!♥</div></body></html>"
    encoded = GuessHtmlEncoding.encode(data)
    encoded.encoding.to_s.should == "UTF-8"

# Pull requests welcome!