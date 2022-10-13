class DuckDB::ResultSet < DB::ResultSet
  @row_index = -1
  @column_index = 0

  macro duckdb_value(kind)
    LibDuckDB.value_{{kind.id}}(self, @column_index, @row_index)
  end

  macro duckdb_unbox(from, to)
    {{to}}.new(Box({{from}}).unbox(column.data))
  end

  macro duckdb_set_string
    lib_value = duckdb_value("varchar")
    string = String.new(lib_value)
    LibDuckDB.free(lib_value)
    string
  end

  def initialize(@statement : Statement)
    check LibDuckDB.execute_prepared(duckdb_statement, out @result)
  end

  def initialize(@statement : UnpreparedStatement)
    check LibDuckDB.query(@statement.connection, @statement.command, out @result)
  end

  protected def do_close
    LibDuckDB.destroy_result(self)
  end

  def move_next : Bool
    @row_index += 1
    return false if @row_index >= row_count
    @column_index = 0
    true
  end

  def read

    unless duckdb_value("is_null").zero?
      @column_index += 1
      return nil
    end

    column_type = LibDuckDB.column_type(self, @column_index)

    value = case column_type
      when .invalid?
        raise Exception.new("Invalid column type at row #{@row_index} and column #{@column_index}")
      when .tinyint?
        duckdb_value("int8")
      when .smallint?
        duckdb_value("int16")
      when .integer?
        duckdb_value("int32")
      when .bigint?
        duckdb_value("int64")
      when .utinyint?
        duckdb_value("uint8")
      when .usmallint?
        duckdb_value("uint16")
      when .uinteger?
        duckdb_value("uint32")
      when .ubigint?
        duckdb_value("uint64")
      when .float?
        duckdb_value("float")
      when .double?
        duckdb_value("double")
      when .boolean?
        duckdb_value("boolean") != 0
      when .varchar?
        duckdb_set_string
      when .blob?
        blob = duckdb_value("blob")
        bytes = Bytes.new(blob.size)
        bytes.copy_from(blob.data.as(UInt8*), blob.size)
        LibDuckDB.free(blob.data)
        bytes
      when .timestamp?
        Timestamp.new duckdb_value("timestamp").micros
      when .date?
        Date.new duckdb_value("date").days
      when .time?
        TimeOfDay.new duckdb_value("time").micros
      when .interval?
        lib_i = duckdb_value("interval")
        Interval.new lib_i.micros, lib_i.days, lib_i.months
      else
        # Treat non supported types as strings
        duckdb_set_string
      end
    @column_index += 1
    value
  end

  def read(t : Time.class) : Time
    read(Timestamp).to_time
  end

  def read(t : Time?.class) : Time?
    read(Timestamp?).try &.to_time
  end

  def column_count : Int32
    LibDuckDB.column_count(self).to_i32
  end

  def column_name(index : Int32) : String
    p = LibDuckDB.column_name(self, index)
    p.null? ? "" : String.new(p)
  end

  def next_column_index : Int32
    @column_index <= column_count ? @column_index : column_count
  end

  protected def row_count
    LibDuckDB.row_count(self).to_i64
  end

  protected def rows_changed
    LibDuckDB.rows_changed(self).to_i64
  end

  protected def duckdb_statement
    @statement.as(Statement)
  end

  def to_unsafe
    pointerof(@result)
  end

  private def check(state : LibDuckDB::State)
    unless state.success?
      message_p = LibDuckDB.result_error(self)

      message = if message_p.null?
                  "Error with command `#{@statement.command}`"
                else
                  String.new(message_p)
                end
      raise Exception.new(message)
    end
  end
end
