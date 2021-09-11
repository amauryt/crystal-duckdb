require "../spec_helper"

describe DuckDB::Timestamp do
  describe "#initialize" do
    it "raises if time is not in UTC" do
      time = Time.local
      expect_raises(ArgumentError) do
        timestamp = DuckDB::Timestamp.new(time)
      end
    end

    it "initializes from a Time instance" do
      time = Time.utc
      timestamp = DuckDB::Timestamp.new(time)
      timestamp.to_time.should be_close(time, 1.second)
    end

    it "initializes from a string" do
      time = Time.utc
      timestamp = DuckDB::Timestamp.new(time.to_s(DuckDB::TIMESTAMP_FORMAT_SECOND))
      timestamp.to_time.should be_close(time, 1.second)
    end

    it "initializes from a date and a time_of_day instances" do
      time = Time.utc
      date = DuckDB::Date.new(time)
      time_of_day = DuckDB::TimeOfDay.new(time)
      timestamp = DuckDB::Timestamp.new(date, time_of_day)
      timestamp.to_time.should be_close(time, 1.second)
    end

    it "initializes from a number of microseconds since UNIX_EPOCH" do
      time = Time.utc
      microseconds = (time - Time::UNIX_EPOCH).total_microseconds.to_i64
      timestamp = DuckDB::Timestamp.new(microseconds)
      timestamp.to_time.should be_close(time, 1.second)
    end
  end

  describe "#to_s" do
    it "converts to an ISO date without timezone" do
      timestamp = DuckDB::Timestamp.new(DuckDB::Date.new(2000, 3, 2), DuckDB::TimeOfDay.new(12, 0, 0))
      timestamp.to_s.should eq "2000-03-02 12:00:00"
    end
  end

  describe "#==" do
    it "returns true for the same timestamps" do
      time1 = Time::UNIX_EPOCH
      time2 = Time::UNIX_EPOCH
      timestamp1 = DuckDB::Timestamp.new(time1)
      timestamp2 = DuckDB::Timestamp.new(time2)
      (timestamp1 == timestamp2).should be_true
    end
    it "returns false for different timestamps" do
      time1 = Time::UNIX_EPOCH
      time2 = Time::UNIX_EPOCH + 1.day
      timestamp1 = DuckDB::Timestamp.new(time1)
      timestamp2 = DuckDB::Timestamp.new(time2)
      (timestamp1 == timestamp2).should be_false
    end
  end
end
