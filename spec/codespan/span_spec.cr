require "../spec_helper"

describe Codespan::Span do
  it "measures string spans" do
    Codespan::Span.from_str("hello").should eq(Codespan::Span.new(0, 5))
  end

  it "merges overlapping, subset, disjoint, and identity spans" do
    a = Codespan::Span.new(1, 5)
    b = Codespan::Span.new(3, 10)
    a.merge(b).should eq(Codespan::Span.new(1, 10))
    b.merge(a).should eq(Codespan::Span.new(1, 10))

    two_four = Codespan::Span.new(2, 4)
    a.merge(two_four).should eq(Codespan::Span.new(1, 5))
    two_four.merge(a).should eq(Codespan::Span.new(1, 5))

    ten_twenty = Codespan::Span.new(10, 20)
    a.merge(ten_twenty).should eq(Codespan::Span.new(1, 20))
    ten_twenty.merge(a).should eq(Codespan::Span.new(1, 20))

    a.merge(a).should eq(a)
  end

  it "detects disjoint spans with off-by-one boundaries" do
    a = Codespan::Span.new(1, 5)
    b = Codespan::Span.new(3, 10)
    a.disjoint(b).should be_false
    b.disjoint(a).should be_false

    two_four = Codespan::Span.new(2, 4)
    a.disjoint(two_four).should be_false
    two_four.disjoint(a).should be_false

    ten_twenty = Codespan::Span.new(10, 20)
    a.disjoint(ten_twenty).should be_true
    ten_twenty.disjoint(a).should be_true

    a.disjoint(a).should be_false

    c = Codespan::Span.new(5, 10)
    a.disjoint(c).should be_true
    c.disjoint(a).should be_true

    d = Codespan::Span.new(0, 1)
    a.disjoint(d).should be_true
    d.disjoint(a).should be_true
  end
end
