require "../spec_helper"

macro test_time_of_day_and_time_span_equality
  span.hours.should eq time_of_day.hour
  span.minutes.should eq time_of_day.minute
  span.seconds.should eq time_of_day.second
  span.nanoseconds.should eq(time_of_day.microsecond * 1000)
end

describe DuckDB::TimeOfDay do
  describe "#initialize" do
    it "raises on invalid time of day" do
      expect_raises(ArgumentError) do
        DuckDB::TimeOfDay.new(25, 70)
      end
    end
    it "initializes from a Time instance" do
      time = Time.utc
      time_of_day = DuckDB::TimeOfDay.new(time)
      time_of_day.hour == time.hour
      time_of_day.minute == time.minute
      time_of_day.second == time.second
      time_of_day.microsecond == time.nanosecond // 1000
    end
    it "initializes from a Time::Span instance" do
      span = Time::Span.new(hours: 12, minutes: 30, seconds: 5, nanoseconds: 999_000_000)
      time_of_day = DuckDB::TimeOfDay.new(span)
      test_time_of_day_and_time_span_equality
    end
    it "raises on a Time::Span with a duration of at least one day" do
      span = Time::Span.new(days: 1)
      expect_raises(ArgumentError) do
        DuckDB::TimeOfDay.new(span)
      end
    end
    it "initializes from a number of microseconds" do
      span = Time::Span.new(hours: 12, minutes: 30, seconds: 5, nanoseconds: 999_000_000)
      microseconds = span.total_microseconds.to_i64
      time_of_day = DuckDB::TimeOfDay.new(microseconds)
      test_time_of_day_and_time_span_equality
    end
  end

  describe "#to_s" do
    it "converts without fractional part" do
      time_of_day = DuckDB::TimeOfDay.new(12, 30, 5)
      time_of_day.to_s.should eq "12:30:05"
    end
    it "converts without trailing zeroes in fractional part" do
      time_of_day = DuckDB::TimeOfDay.new(12, 30, 5, 900_000)
      time_of_day.to_s.should eq "12:30:05.9"
    end
    it "converts with leaging zeroes in fractional part" do
      time_of_day = DuckDB::TimeOfDay.new(12, 30, 5, 9)
      time_of_day.to_s.should eq "12:30:05.000009"
    end
  end

  describe "#to_span" do
    it "converts to a Time instance in UTC" do
      time_of_day = DuckDB::TimeOfDay.new(12, 30, 5, 999)
      span = time_of_day.to_span
      span.should be_a Time::Span
      test_time_of_day_and_time_span_equality
    end
  end

  describe "#==" do
    it "returns true for the same times of day" do
      time_of_day1 = DuckDB::TimeOfDay.new(10, 2, 1)
      time_of_day2 = DuckDB::TimeOfDay.new("10:02:01")
      (time_of_day1 == time_of_day2).should be_true
    end
    it "returns false for different times of day" do
      time_of_day1 = DuckDB::TimeOfDay.new(10, 2, 1)
      time_of_day2 = DuckDB::TimeOfDay.new(11, 2, 1)
      (time_of_day1 == time_of_day2).should be_false
    end
  end
end
