class DuckDB::Appender
  getter table_name : String

  def initialize(connection : Connection, @table_name)
    tc = @table_name.split('.')
    case tc.size
    when 1
      ts = ""
      tn = tc[0]
    when 2
      ts = tc[0]
      tn = tc[1]
    else
      raise Exception.new("Invalid table name '#{@table_name}'")
    end
    state = LibDuckDB.appender_create(connection, ts, tn, out @appender)
    unless state.success?
      raise Exception.new("Failed to create appender for table '#{@table_name}'")
    end
  end

  def <<(value : Nil)
    check LibDuckDB.append_null(self), value
    self
  end

  def <<(value : Bool)
    check LibDuckDB.append_bool(self, value ? 1_u8 : 0_u8), value
    self
  end

  {% for name in ["begin_row", "end_row", "flush", "close"] %}
    def {{name.id}}
      unless LibDuckDB.appender_{{name.id}}(self).success?
        raise Exception.new("Failed to {{name.id}} for table '#{@table_name}'")
      end
    end
  {% end %}

  {% for name in ["Int8", "Int16", "Int32", "Int64", "UInt8", "UInt16", "UInt32", "UInt64"] %}
    def <<(value : {{name.id}})
      check LibDuckDB.append_{{name.id.downcase}}(self, value), value
      self
    end
  {% end %}

  def <<(value : Float32)
    check LibDuckDB.append_float(self, value), value
    self
  end

  def <<(value : Float64)
    check LibDuckDB.append_double(self, value), value
    self
  end

  def <<(value : String)
    check LibDuckDB.append_varchar(self, value), value
    self
  end

  def <<(value : Date)
    check LibDuckDB.append_date(self, value), value
    self
  end

  def <<(value : TimeOfDay)
    check LibDuckDB.append_time(self, value), value
    self
  end

  def <<(value : Timestamp)
    check LibDuckDB.append_timestamp(self, value), value
    self
  end

  def <<(value : Interval)
    check LibDuckDB.append_interval(self, value), value
    self
  end

  def <<(value : Bytes)
    check LibDuckDB.append_blob(self, value, value.size), value
    self
  end

  def <<(value : Time)
    self << Timestamp.new(value)
  end

  def row(&block)
    begin_row
    yield self
    end_row
  end

  # :nodoc:
  def finalize
    LibDuckDB.appender_destroy(pointerof(@appender))
  end

  # :nodoc:
  def to_unsafe
    @appender
  end

  private def check(state, value)
    unless state.success?
      raise Exception.new("Failed to append value '#{value}' for table '#{@table_name}'")
    end
  end
end
