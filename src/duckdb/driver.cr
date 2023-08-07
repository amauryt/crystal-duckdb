class DuckDB::Driver < DB::Driver
  class ConnectionBuilder < ::DB::ConnectionBuilder
    def initialize(@options : ::DB::Connection::Options, @duckdb_options : Connection::Options)
    end
    

    def build : ::DB::Connection
      Connection.new(@options, @duckdb_options)
    end
  end

  def connection_builder(uri : URI) : ::DB::ConnectionBuilder
    params = HTTP::Params.parse(uri.query || "")
    ConnectionBuilder.new(connection_options(params), DuckDB::Connection::Options.from_uri(uri))
  end

end

DB.register_driver "duckdb", DuckDB::Driver
