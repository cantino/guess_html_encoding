# encoding: UTF-8
require 'spec_helper'

describe "GuessHtmlEncoding" do
  describe "#guess" do
    it "prefers headers" do
      guess = GuessHtmlEncoding.guess("<html><body><div>hi!</div></body></html>",
                                      "Hello: world\nContent-Type: text/html; charset=utf-8\nFoo: bar")
      guess.should == "UTF-8"
    end

    it "accepts meta tags" do
      guess = GuessHtmlEncoding.guess('<html><head><meta http-equiv="content-type" content="text/html; charset=utf-8"></head><body><div>hi!</div></body></html>')
      guess.should == "UTF-8"
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
    it "should work on incorrectly encoded pages" do
      data = "<html><head><meta http-equiv='content-type' content='text/html; charset=utf8;'></head><body><div>hi!\xc2</div></body></html>"
      data.force_encoding("ASCII-8BIT")
      data.should be_valid_encoding # everything is valid in binary

      GuessHtmlEncoding.guess(data).should == "UTF-8" # because the page says so!
      data.force_encoding("UTF-8").should_not be_valid_encoding # because of the bad byte sequence \xc2

      encoded = GuessHtmlEncoding.encode(data)
      encoded.encoding.to_s.should == "UTF-8"
      encoded.should be_valid_encoding
    end
  end
end