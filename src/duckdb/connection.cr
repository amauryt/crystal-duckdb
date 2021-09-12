class DuckDB::Connection < DB::Connection
  def initialize(database)
    super
    filename = self.class.filename(database.uri)
    if filename == ":memory:"
      check LibDuckDB.open(nil, out @db)
    else
      check LibDuckDB.open(filename, out @db)
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
