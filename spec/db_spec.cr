require "./spec_helper"
require "db/spec"

class DB::DriverSpecs # Monkey-patch to exclude specs not supported by DuckDB
  EXCLUDED_ITS = [
    "nested transactions: can read inside transaction and rollback after",
  ]

  def it(description = "assert", prepared = :default, file = __FILE__, line = __LINE__, end_line = __END_LINE__, &block : DB::Database ->)
    unless EXCLUDED_ITS.includes?(description)
      @its << SpecIt.new(description, prepared, file, line, end_line, block)
    end
  end
end

private def cast_if_necessary(expr, sql_type)
  case sql_type
  when "DATE", "TIME", "TIMESTAMP", "BLOB", "INTERVAL"
    "cast(#{expr} as #{sql_type})"
  else
    expr
  end
end

DB::DriverSpecs(DuckDB::Any).run do
  support_unprepared true

  before do
    File.delete(DB_FILENAME) if File.exists?(DB_FILENAME)
  end
  after do
    File.delete(DB_FILENAME) if File.exists?(DB_FILENAME)
  end

  connection_string "duckdb:#{DB_FILENAME}"

  date = DuckDB::Date.new(2020, 1, 1)
  time_of_day = DuckDB::TimeOfDay.new(10, 11, 12, 1300)
  timestamp = DuckDB::Timestamp.new(date, time_of_day)

  sample_value true, "BOOLEAN", "true", type_safe_value: false
  sample_value false, "BOOLEAN", "false", type_safe_value: false
  sample_value 1_i8, "TINYINT", "1", type_safe_value: false
  sample_value 1_i16, "SMALLINT", "1", type_safe_value: false
  sample_value 1, "INTEGER", "1", type_safe_value: false
  sample_value 1_i64, "BIGINT", "1", type_safe_value: false
  sample_value 1_u8, "UTINYINT", "1", type_safe_value: false
  sample_value 1_u16, "USMALLINT", "1", type_safe_value: false
  sample_value 1_u32, "UINTEGER", "1", type_safe_value: false
  sample_value 1_u64, "UBIGINT", "1", type_safe_value: false
  sample_value "hello", "VARCHAR", "'hello'", type_safe_value: true
  sample_value 1.5_f32, "FLOAT", "1.5", type_safe_value: false
  sample_value 1.5_f64, "DOUBLE", "1.5", type_safe_value: false
  sample_value date, "DATE", "'2020-01-01'", type_safe_value: false
  sample_value time_of_day, "TIME", "'10:11:12.0013'", type_safe_value: false # subsecond
  sample_value timestamp, "TIMESTAMP", "'2020-01-01 10:11:12.0013'", type_safe_value: false
  sample_value DuckDB::TimeOfDay.new(10, 11, 12), "TIME", "'10:11:12'", type_safe_value: false # second
  sample_value DuckDB::Interval.new(0, 1, 0), "INTERVAL", "'1 DAY'", type_safe_value: false
  sample_value timestamp.to_time, "TIMESTAMP", "'2020-01-01 10:11:12.0013'", type_safe_value: false

  ary = UInt8[0x44, 0x75, 0x63, 0x6b, 0x44, 0x42]
  sample_value Bytes.new(ary.to_unsafe, ary.size), "BLOB", "'DuckDB'" # , type_safe_value: false

  binding_syntax do |index|
    "?"
  end

  create_table_1column_syntax do |table_name, col1|
    "create table #{table_name} (#{col1.name} #{col1.sql_type} #{col1.null ? "NULL" : "NOT NULL"})"
  end

  create_table_2columns_syntax do |table_name, col1, col2|
    "create table #{table_name} (#{col1.name} #{col1.sql_type} #{col1.null ? "NULL" : "NOT NULL"}, #{col2.name} #{col2.sql_type} #{col2.null ? "NULL" : "NOT NULL"})"
  end

  select_1column_syntax do |table_name, col1|
    "select #{cast_if_necessary(col1.name, col1.sql_type)} from #{table_name}"
  end

  select_2columns_syntax do |table_name, col1, col2|
    "select #{cast_if_necessary(col1.name, col1.sql_type)}, #{cast_if_necessary(col2.name, col2.sql_type)} from #{table_name}"
  end

  select_count_syntax do |table_name|
    "select count(*) from #{table_name}"
  end

  select_count_syntax do |table_name|
    "select count(*) from #{table_name}"
  end

  select_scalar_syntax do |expression, sql_type|
    # Explicit cast necessary only for null value binding on single expression spec
    if expression == "?" && "VARCHAR"
      "select cast(#{expression} as #{sql_type})"
    else
      "select #{cast_if_necessary(expression, sql_type)}"
    end
  end

  insert_1column_syntax do |table_name, col, expression|
    "insert into #{table_name} (#{col.name}) values (#{expression})"
  end

  insert_2columns_syntax do |table_name, col1, expr1, col2, expr2|
    "insert into #{table_name} (#{col1.name}, #{col2.name}) values (#{expr1}, #{expr2})"
  end

  drop_table_if_exists_syntax do |table_name|
    "drop table if exists #{table_name}"
  end

  it "ensures statements are closed" do |db|
    db.exec %(create table if not exists a (i int not null, str text not null);)
    db.exec %(insert into a (i, str) values (23, 'bai bai');)

    2.times do |i|
      DB.open db.uri do |db|
        begin
          db.query("SELECT i, str FROM a WHERE i = ?", 23) do |rs|
            rs.move_next
            break
          end
        rescue e : DuckDB::Exception
          fail("Expected no exception, but got \"#{e.message}\"")
        end

        begin
          db.exec("UPDATE a SET i = ? WHERE i = ?", 23, 23)
        rescue e : DuckDB::Exception
          fail("Expected no exception, but got \"#{e.message}\"")
        end
      end
    end
  end
end
