require "../spec_helper"

describe Driver do
  it "should register duckdb name" do
    DB.driver_class("duckdb").should eq(DuckDB::Driver)
  end

  it "should use database option as file to open" do
    with_db do |db|
      db.checkout.should be_a(DuckDB::Connection)
      File.exists?(DB_FILENAME).should be_true
    end
  end

  describe "DuckDB configuration" do
    it "should accept duckdb configuration params" do
      ["nulls_first", "nulls_last"].each do |value|
        with_db "null_order=#{value}" do |db|
          config = db.scalar "SELECT current_setting('null_order')"
          config.should eq value
        end
      end
    end

    it "should raise an exception on invalid duckdb configuration params" do
      expect_raises(DuckDB::Exception) do
        value = "invalid"
        with_db "null_order=#{value}" do |db|
          config = db.scalar "SELECT current_setting('null_order')"
        end
      end
    end
  end
end
