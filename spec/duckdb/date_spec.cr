require "../spec_helper"

macro test_date_and_time_equality
  date.year.should eq time.year
  date.month.should eq time.month
  date.day.should eq time.day
end

describe DuckDB::Date do
  describe "#initialize" do
    it "raises on invalid date" do
      expect_raises(ArgumentError) do
        DuckDB::Date.new(2000, 2, 30)
      end
    end

    it "initializes from a Time instance" do
      time = Time.utc(2000, 2, 1)
      date = DuckDB::Date.new(time)
      test_date_and_time_equality
    end

    it "initializes from a String" do
      time = Time.utc(2000, 2, 1)
      date = DuckDB::Date.new("2000-02-01")
      test_date_and_time_equality
    end

    it "initializes from a LibDuckDB::Date instance" do
      lib_date = DuckDB::LibDuckDB::Date.new
      lib_date.year = 2000
      lib_date.month = 2_i8
      lib_date.day = 1_i8
      date = DuckDB::Date.new(lib_date)
      date.year.should eq lib_date.year
      date.month.should eq lib_date.month
      date.day.should eq lib_date.day
    end
  end

  describe "#to_s" do
    it "converts to ISO format string" do
      date = DuckDB::Date.new(2000, 2, 1)
      date.to_s.should eq "2000-02-01"
    end
  end

  describe "#to_time" do
    it "converts to a Time instance in UTC" do
      date = DuckDB::Date.new(2000, 2, 1)
      time = date.to_time
      time.should be_a Time
      time.utc?.should be_true
      test_date_and_time_equality
    end
  end

  describe "#==" do
    it "returns true for the same dates" do
      date1 = DuckDB::Date.new(2000, 2, 1)
      date2 = DuckDB::Date.new("2000-02-01")
      (date1 == date2).should be_true
    end
    it "returns false for different dates" do
      date1 = DuckDB::Date.new(2000, 2, 1)
      date2 = DuckDB::Date.new(2001, 2, 1)
      (date1 == date2).should be_false
    end
  end
end
