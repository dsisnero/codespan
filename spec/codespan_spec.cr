require "./spec_helper"

describe Codespan do
  it "exposes a semantic version string" do
    Codespan::VERSION.should match(/\A\d+\.\d+\.\d+/)
  end
end
