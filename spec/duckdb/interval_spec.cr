require "../spec_helper"

describe DuckDB::Interval do
  describe "empty interval" do
    it "converts to empty Time::Span" do
      DuckDB::Interval.new.to_span.should eq(Time::Span.new)
    end

    it "converts to empty Time::MonthSpan" do
      DuckDB::Interval.new.to_month_span.should eq(Time::MonthSpan.new(0))
    end
  end

  describe "overflowing for Time::Span" do
    it "raises when overflowing" do
      expect_raises(Exception) do
        DuckDB::Interval.new(months: -1).to_span
      end
      expect_raises(DuckDB::Exception) do
        DuckDB::Interval.new(months: 1).to_span
      end
    end

    it "allows to ignore overflow" do
      span = DuckDB::Interval.new(microseconds: 123_000_000, months: 2).to_span(approx_months: 30)
      span.should eq(Time::Span.new(days: 60, seconds: 123))
    end
  end

  describe "to_span" do
    it "adds days to days contained in microseconds" do
      # 13.17:23:26.535897
      interval = DuckDB::Interval.new(microseconds: 149_006_535_897, days: 12)
      interval.to_span.should eq(Time::Span.new(days: 13, hours: 17, seconds: 1406, nanoseconds: 535_897_000))
    end

    it "maximum values can be covered by Time::Span" do
      # MAX = 9_223_372_036_854_775_807
      interval = DuckDB::Interval.new(microseconds: Int64::MAX, days: Int32::MAX)
      interval.to_span.should eq(Time::Span.new(days: Int32::MAX, seconds: 9223372036854, nanoseconds: 775_807_000))
    end
    it "minimum values can be covered by Time::Span" do
      # MIN = -9_223_372_036_854_775_808
      interval = DuckDB::Interval.new(microseconds: Int64::MIN, days: Int32::MIN)
      interval.to_span.should eq(Time::Span.new(days: Int32::MIN, seconds: -9223372036854, nanoseconds: -775_808_000))
    end
  end

  describe "to_month_span" do
    it "does not add days to months" do
      interval = DuckDB::Interval.new(months: 123, days: 45)
      interval.to_month_span.should eq(Time::MonthSpan.new(123))
    end
  end
end