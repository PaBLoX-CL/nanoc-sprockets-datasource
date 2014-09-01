require "spec_helper"

describe Nanoc::Sprockets do
  describe "VERSION" do
    it "returns the version" do
      expect(Nanoc::Sprockets::VERSION).to eq('0.0.2')
    end
  end
end
