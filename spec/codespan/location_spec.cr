require "../spec_helper"

describe Codespan::Location do
  it "constructs locations from raw indices" do
    Codespan::Location.new(0, 3).should eq(
      Codespan::Location.new(Codespan::LineIndex.from(0), Codespan::ColumnIndex.from(3))
    )
  end
end
