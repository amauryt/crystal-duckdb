class DuckDB::Driver < DB::Driver
  def build_connection(context : DB::ConnectionContext) : DuckDB::Connection
    DuckDB::Connection.new(context)
  end
end

DB.register_driver "duckdb", DuckDB::Driver
