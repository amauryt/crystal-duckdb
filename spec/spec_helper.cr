require "spec"
require "../src/duckdb"

include DuckDB

DB_FILENAME = "./test.db"

def with_db(&block : DB::Database ->)
  File.delete?(DB_FILENAME)
  DB.open "duckdb:#{DB_FILENAME}", &block
ensure
  File.delete?(DB_FILENAME)
end

def with_cnn(&block : DB::Connection ->)
  File.delete?(DB_FILENAME)
  DB.connect "duckdb:#{DB_FILENAME}", &block
ensure
  File.delete?(DB_FILENAME)
end

def with_db(config, &block : DB::Database ->)
  uri = "duckdb:#{DB_FILENAME}?#{config}"
  File.delete?(DB_FILENAME)
  DB.open uri, &block
ensure
  File.delete?(DB_FILENAME)
end
