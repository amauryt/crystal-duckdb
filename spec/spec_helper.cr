require "spec"
require "../src/duckdb"

include DuckDB

DB_FILENAME = "./test.db"

def with_db(&block : DB::Database ->)
  File.delete(DB_FILENAME) rescue nil
  DB.open "duckdb:#{DB_FILENAME}", &block
ensure
  File.delete(DB_FILENAME)
end

def with_cnn(&block : DB::Connection ->)
  File.delete(DB_FILENAME) rescue nil
  DB.connect "duckdb:#{DB_FILENAME}", &block
ensure
  File.delete(DB_FILENAME)
end

def with_db(config, &block : DB::Database ->)
  uri = "duckdb:#{config}"
  filename = DuckDB::Connection.filename(URI.parse(uri))
  File.delete(filename) rescue nil
  DB.open uri, &block
ensure
  File.delete(filename) if filename
end
