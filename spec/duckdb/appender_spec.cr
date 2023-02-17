require "../spec_helper"

macro it_appends(klass, datatype, value)
  it "appends {{klass.id}}" do
    DB.connect DuckDB::IN_MEMORY do |cnn|
      cnn.exec "CREATE TABLE test_table (test_field {{datatype.id}});"
      cnn.appender("test_table") do |appender|
        appender.row do |r|
          r << {{value}}
        end
      end  
      actual = cnn.scalar("SELECT test_field FROM test_table;")
      actual.should eq {{value}}
    end
  end
end

describe DuckDB::Appender do
  describe "#initialize" do
    it "raises on non-existent table" do
      DB.connect DuckDB::IN_MEMORY do |cnn|
        expect_raises(DuckDB::Exception) do
          cnn.appender("no_table")
        end
      end
    end
  end

  it_appends Nil, "BOOLEAN", nil
  it_appends Bool, "BOOLEAN", true
  it_appends Int8, "TINYINT", 1_i8
  it_appends Int16, "SMALLINT", 1_i16
  it_appends Int32, "INTEGER", 1_i32
  it_appends Int64, "BIGINT", 1_i64
  it_appends UInt8, "UTINYINT", 1_u8
  it_appends UInt16, "USMALLINT", 1_u16
  it_appends UInt32, "UINTEGER", 1_u32
  it_appends UInt64, "UBIGINT", 1_u64
  it_appends Float32, "FLOAT", 1.5_f32
  it_appends Float64, "DOUBLE", 1.5_f64
  it_appends String, "VARCHAR", "hello"
  it_appends DuckDB::Date, "DATE", DuckDB::Date.new(2010, 1, 1)
  it_appends DuckDB::TimeOfDay, "TIME", DuckDB::TimeOfDay.new(10, 2, 1)
  it_appends DuckDB::Timestamp, "TIMESTAMP", DuckDB::Timestamp.new(Time::UNIX_EPOCH)
  it_appends DuckDB::Interval, "INTERVAL", DuckDB::Interval.new(1, 0, 0)
  it_appends Int128, "HUGEINT", 170141183460469231731687303715884105727_i128

  ary = UInt8[0x44, 0x75, 0x63, 0x6b, 0x44, 0x42]
  it_appends Bytes, "BLOB", Bytes.new(ary.to_unsafe, ary.size)
end
