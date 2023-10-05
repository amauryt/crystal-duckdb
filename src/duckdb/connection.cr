class DuckDB::Connection < DB::Connection
  record Options, filename : String, config_params : Hash(String, String) do
    CRYSTAL_DB_PARAM_KEYS = %[
      initial_pool_size
      max_pool_size
      max_idle_pool_size
      checkout_timeout
      retry_attempts
      retry_delay
      prepared_statements
    ]

    def initialize(@filename, @config_params)
    end

    def self.from_uri(uri : URI)
      filename = URI.decode_www_form((uri.host || "") + uri.path)
      params = HTTP::Params.parse(uri.query || "")
      config_params = Hash(String, String).new
      params.each do |param|
        config_params[param[0]] = param[1] unless CRYSTAL_DB_PARAM_KEYS.includes?(param[0])
      end
      Options.new(filename, config_params)
    end
  end

  def initialize(options : ::DB::Connection::Options, duckdb_options : Options)
    super(options)
    if duckdb_options.config_params.empty?
      check LibDuckDB.open(duckdb_options.filename, out @db)
    else
      LibDuckDB.create_config(out config)
      begin
        duckdb_options.config_params.each do |key, value|
          state = LibDuckDB.set_config(config, key, value)
          raise Exception.new("Configuration error for '#{key}' with value '#{value}'") unless state.success?
        end
        state = LibDuckDB.open_ext(duckdb_options.filename, out @db, config, out error_msg_p)
        raise Exception.new(String.new(error_msg_p)) unless state.success?
      ensure
        LibDuckDB.destroy_config(pointerof(config))
      end
    end
    check LibDuckDB.connect(@db, out @conn)
  end

  def appender(table_name)
    Appender.new(self, table_name)
  end

  def appender(table_name, &block)
    appender = Appender.new(self, table_name)
    yield appender
    appender.close
  end

  def do_close
    super
    LibDuckDB.disconnect(pointerof(@conn))
    LibDuckDB.close(pointerof(@db))
  end

  def build_prepared_statement(query) : Statement
    Statement.new(self, query)
  end

  def build_unprepared_statement(query) : UnpreparedStatement
    UnpreparedStatement.new(self, query)
  end

  def to_unsafe
    @conn
  end

  private def check(state)
    raise Exception.new("Connection error") unless state == LibDuckDB::State::Success
  end
end
