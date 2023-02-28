require "../spec_helper"

describe DuckDB::ResultSet do
  it "reads integer data types" do
    with_db do |db|
      db.exec "CREATE TABLE test_table (test_int integer)"
      db.exec "INSERT INTO test_table (test_int) values (?)", 42
      db.query("SELECT test_int FROM test_table") do |rs|
        rs.each do
          rs.read.should eq(42)
        end
      end
    end
  end

  it "reads string data types" do
    with_db do |db|
      db.exec "CREATE TABLE test_table (test_text text)"
      db.exec "INSERT INTO test_table (test_text) values (?), (?)", "abc", "123"
      db.query("SELECT test_text FROM test_table") do |rs|
        rs.each do
          rs.read.should match(/abc|123/)
        end
      end
    end
  end

  it "reads time data types" do
    with_db do |db|
      db.exec "CREATE TABLE test_table (test_date datetime)"
      timestamp = Time.utc
      db.exec "INSERT INTO test_table (test_date) values (?)", timestamp.to_s
      db.query("SELECT test_date FROM test_table") do |rs|
        rs.each do
          rs.read(Time).should be_close(timestamp, 1.second)
        end
      end
    end
  end

  it "reads timestamps fields, too" do
    with_db do |db|
      db.exec "CREATE TABLE test_table (test_date timestamp)"
      timestamp = Timestamp.new(Time.utc)
      db.exec "INSERT INTO test_table (test_date) values (?)", timestamp.to_s
      db.query("SELECT CAST(test_date as TIMESTAMP) FROM test_table") do |rs|
        rs.each do
          rs.read(Timestamp).to_time.should be_close(timestamp.to_time, 1.second)
        end
      end
    end
  end

  it "reads interval times" do
    with_cnn do |cnn|
      cnn.exec "CREATE TABLE test_table (test_interval INTERVAL)"
      cnn.exec "INSERT INTO test_table (test_interval) values (INTERVAL '1 YEAR')"
      cnn.exec "INSERT INTO test_table (test_interval) values (?)", Interval.new(0, 0, 1)
      cnn.exec "INSERT INTO test_table (test_interval) values (INTERVAL '1 WEEK')"
      cnn.exec "INSERT INTO test_table (test_interval) values (?)", Interval.new(0, 1, 0)
      cnn.exec "INSERT INTO test_table (test_interval) values (INTERVAL '1 HOUR')"
      expected = [
        Interval.new(0, 0, 12),
        Interval.new(0, 0, 1),
        Interval.new(0, 7, 0),
        Interval.new(0, 1, 0),
        Interval.new(3_600_000_000, 0, 0)
      ]
      results = cnn.query_all("SELECT CAST(test_interval AS INTERVAL) FROM test_table", as: Interval)
      results.should eq expected
    end
  end

  it "reads null fields, too" do
    with_cnn do |cnn|
      cnn.exec "CREATE TABLE test_table (i int, b boolean, c varchar)"
      cnn.exec "INSERT INTO test_table values (NULL, true, 'a')"
      cnn.exec "INSERT INTO test_table values (1, false, 'b')"
      cnn.exec "INSERT INTO test_table values (?, ?, ?)", 2, nil, nil
      cnn.exec "INSERT INTO test_table values (NULL, true, NULL)"
      cnn.exec "INSERT INTO test_table values (NULL, NULL, NULL)"
      cnn.exec "INSERT INTO test_table values (1012, true, 'c')"
      expected = [
        {i: nil, b: true, c: "a"},
        {i: 1, b: false, c: "b"},
        {i: 2, b: nil, c: nil},
        {i: nil, b: true, c: nil},
        {i: nil, b: nil, c: nil},
        {i: 1012, b: true, c: "c"},
      ]
      results = cnn.query_all("SELECT * FROM test_table", as: {i: Int32?, b: Bool?, c: String?})
      results.should eq expected
    end
  end
end
