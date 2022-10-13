class DuckDB::Statement < DB::Statement
  def initialize(connection, command)
    super(connection, command)
    LibDuckDB.prepare(duckdb_connection, command, out @statement)
  end

  protected def perform_query(args : Enumerable) : DB::ResultSet
    args.each_with_index(1) do |arg, index|
      bind_arg(index, arg)
    end
    ResultSet.new(self)
  end

  protected def perform_exec(args : Enumerable) : DB::ExecResult
    args.each_with_index(1) do |arg, index|
      bind_arg(index, arg)
    end
    result = ResultSet.new(self)
    DB::ExecResult.new result.rows_changed.to_i64, result.rows_changed.to_i64
  end

  protected def do_close
    LibDuckDB.destroy_prepare(pointerof(@statement))
  end

  private def bind_arg(index, value : Nil)
    check LibDuckDB.bind_null(self, index)
  end

  private def bind_arg(index, value : Bool)
    check LibDuckDB.bind_boolean(self, index, value ? 1_u8 : 0_u8)
  end

  {% for name in ["Int8", "Int16", "Int32", "Int64", "UInt8", "UInt16", "UInt32", "UInt64"] %}
    private def bind_arg(index, value : {{name.id}})
      check LibDuckDB.bind_{{name.id.downcase}}(self, index, value)
    end
  {% end %}

  private def bind_arg(index, value : Float32)
    check LibDuckDB.bind_float(self, index, value)
  end

  private def bind_arg(index, value : Float64)
    check LibDuckDB.bind_double(self, index, value)
  end

  private def bind_arg(index, value : String)
    check LibDuckDB.bind_varchar(self, index, value)
  end

  private def bind_arg(index, value : Date)
    check LibDuckDB.bind_date(self, index, value)
  end

  private def bind_arg(index, value : TimeOfDay)
    check LibDuckDB.bind_time(self, index, value)
  end

  private def bind_arg(index, value : Timestamp)
    check LibDuckDB.bind_timestamp(self, index, value)
  end

  private def bind_arg(index, value : Time)
    bind_arg(index, Timestamp.new(value))
  end

  private def bind_arg(index, value : Interval)
    check LibDuckDB.bind_interval(self, index, value)
  end

  private def bind_arg(index, value : Bytes)
    check LibDuckDB.bind_blob(self, index, value, value.size)
  end

  private def bind_arg(index, value)
    raise "#{self.class} does not support #{value.class} params"
  end

  private def check(state)
    unless state.success?
      raise Exception.new(String.new(LibDuckDB.prepare_error(self)))
    end
  end

  protected def duckdb_connection
    @connection.as(Connection).to_unsafe
  end

  def to_unsafe
    @statement
  end
end
