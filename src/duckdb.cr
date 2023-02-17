require "db"
require "./duckdb/**"

module DuckDB
  IN_MEMORY = "duckdb://%3Amemory%3A"

  DATE_FORMAT = "%Y-%m-%d"

  TIME_OF_DAY_FORMAT_SUBSECOND = "%H:%M:%S.%6N"
  TIME_OF_DAY_FORMAT_SECOND    = "%H:%M:%S"

  TIMESTAMP_FORMAT_SUBSECOND = "#{DATE_FORMAT} #{TIME_OF_DAY_FORMAT_SUBSECOND}"
  TIMESTAMP_FORMAT_SECOND    = "#{DATE_FORMAT} #{TIME_OF_DAY_FORMAT_SECOND}"

  TIMEZONE = Time::Location::UTC

  alias Any = DB::Any | Int8 | Int16 | UInt8 | UInt16 | UInt32 | UInt64 | DuckDB::Date | DuckDB::TimeOfDay | DuckDB::Timestamp | DuckDB::Interval | Int128
end
