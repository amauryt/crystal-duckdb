class DuckDB::Connection < DB::Connection

  CRYSTAL_DB_PARAM_KEYS = %[
    initial_pool_size
    max_pool_size
    max_idle_pool_size
    checkout_timeout
    retry_attempts
    retry_delay
    prepared_statements
  ]

  def initialize(database)
    super
    filename = self.class.filename(database.uri)
    config_params = self.class.config_params(database.uri)
    if config_params.empty?
      check LibDuckDB.open(filename, out @db)
    else
      LibDuckDB.create_config(out config)
      begin
        config_params.each do |key, value|
          state = LibDuckDB.set_config(config, key, value)
          raise Exception.new("Configuration error for '#{key}' with value '#{value}'") unless state.success?
        end
        state = LibDuckDB.open_ext(filename, out @db, config, out error_msg_p)
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

  def self.filename(uri : URI)
    URI.decode_www_form((uri.host || "") + uri.path)
  end

  def self.config_params(uri : URI)
    params = HTTP::Params.parse(uri.query || "")
    params.reject { |param| CRYSTAL_DB_PARAM_KEYS.includes?(param[0]) }
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
