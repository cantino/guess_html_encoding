# encoding: UTF-8
require 'spec_helper'

describe "GuessHtmlEncoding" do
  describe "#guess" do
    it "can use headers" do
      guess = GuessHtmlEncoding.guess("<html><body><div>hi!</div></body></html>",
                                      "Hello: world\nContent-Type: text/html; charset=LATIN1\nFoo: bar")
      guess.should == "ISO-8859-1"
    end

    it "accepts headers as a hash as well" do
      guess = GuessHtmlEncoding.guess("<html><body><div>hi!</div></body></html>",
          {"Hello" => "world", "Content-Type" => "text/html; charset=LATIN1", "Foo" => "bar"})
      guess.should == "ISO-8859-1"
    end

    it "accepts meta tags" do
      guess = GuessHtmlEncoding.guess('<html><head><meta http-equiv="content-type" content="text/html; charset=LATIN1"></head><body><div>hi!</div></body></html>')
      guess.should == "ISO-8859-1"
    end

    it "works okay when there is a semi-colon after the encoding with headers" do
      guess = GuessHtmlEncoding.guess("<html><body><div>hi!</div></body></html>",
                                      "Hello: world\nContent-Type: text/html; charset=utf-8;\nFoo: bar")
      guess.should == "UTF-8"
    end

    it "works okay when there is a semi-colon after the encoding with meta-tags" do
      guess = GuessHtmlEncoding.guess('<html><head><meta http-equiv="content-type" content="text/html; charset=utf-8;"></head><body><div>hi!</div></body></html>')
      guess.should == "UTF-8"
    end

    it "converts UTF8 to UTF-8" do
      guess = GuessHtmlEncoding.guess('<html><head><meta http-equiv="content-type" content="text/html; charset=utf8;"></head><body><div>hi!</div></body></html>')
      guess.should == "UTF-8"
    end

    it "converts CP-1251 to CP1251" do
      guess = GuessHtmlEncoding.guess('<html><head><meta http-equiv="content-type" content="text/html; charset=cp-1251;"></head><body><div>hi!</div></body></html>')
      guess.should == "CP1251"
    end

    it "skips the header content type if it's invalid" do
      guess = GuessHtmlEncoding.guess('<html><head><meta http-equiv="content-type" content="text/html; charset=utf8;"></head><body><div>hi!</div></body></html>',
                                      "Hello: world\nContent-Type: text/html; charset=RU;\nFoo: bar")
      guess.should == "UTF-8"
    end

  end

  describe "#encode" do
    it "should work on correctly encoded pages" do
      data = "<html><head><meta http-equiv='content-type' content='text/html; charset=utf8;'></head><body><div>hi!♥</div></body></html>"
      data.force_encoding("ASCII-8BIT")
      data.should be_valid_encoding # everything is valid in binary

      GuessHtmlEncoding.guess(data).should == "UTF-8" # because the page says so!
      data.force_encoding("UTF-8").should be_valid_encoding # because it really is utf-8

      encoded = GuessHtmlEncoding.encode(data)
      encoded.encoding.to_s.should == "UTF-8"
      encoded.should be_valid_encoding
    end

    it "should work on incorrectly encoded pages" do
      data = "<html><head><meta http-equiv='content-type' content='text/html; charset=utf8;'></head><body><div>hi!\xc2</div></body></html>"
      data.force_encoding("ASCII-8BIT")
      data.should be_valid_encoding # everything is valid in binary

      GuessHtmlEncoding.guess(data).should == "UTF-8" # because the page says so!
      data.force_encoding("UTF-8").should_not be_valid_encoding # because of the bad byte sequence \xc2 which is not valid UTF-8

      encoded = GuessHtmlEncoding.encode(data)
      encoded.encoding.to_s.should == "UTF-8"
      encoded.should be_valid_encoding
    end

    it "should work on pages encoded with an unloaded encoding" do
      data = "<html><head><meta http-equiv='content-type' content='text/html; charset=x-mac-roman;'></head><body><div>hi!</div></body></html>"
      data.force_encoding("ASCII-8BIT")
      data.should be_valid_encoding # everything is valid in binary

      GuessHtmlEncoding.guess(data).should == "X-MAC-ROMAN" # because the page says so!

      encoded = GuessHtmlEncoding.encode(data)
      encoded.encoding.to_s.should == "UTF-8"
      encoded.should be_valid_encoding
    end
  end

  describe "#encoding_loaded?" do
    it 'returns true for all loaded encodings' do
      Encoding.name_list.each do |name|
        GuessHtmlEncoding.encoding_loaded?(name).should be_true
      end
    end
    it 'returns false for irregular or unloaded encoding' do
      GuessHtmlEncoding.encoding_loaded?('_WHY').should be_false
    end
  end
end
