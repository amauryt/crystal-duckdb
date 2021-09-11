class DuckDB::ResultSet < DB::ResultSet
  @row_index = -1
  @column_index = 0

  macro duckdb_value(kind)
    LibDuckDB.value_{{kind.id}}(self, @column_index, @row_index)
  end

  macro duckdb_unbox(from, to)
    puts column.data.to_s
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
    return false if @row_index >= @result.row_count
    @column_index = 0
    true
  end

  def read
    column = @result.columns[@column_index]
    unless column.nullmask[@row_index].zero?
      @column_index += 1
      return nil
    end

    value =
      case column.type
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
        # puts Box(LibDuckDB::CBool).unbox(column.data)
        duckdb_value("boolean") != 0
      when .varchar?
        duckdb_set_string
      when .timestamp?
        Timestamp.new duckdb_set_string
      when .date?
        Date.new duckdb_set_string
      when .time?
        TimeOfDay.new duckdb_set_string
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
    @result.column_count.to_i32
  end

  def column_name(index : Int32) : String
    String.new LibDuckDB.column_name(pointerof(@result), index)
  end

  protected def row_count
    @result.row_count
  end

  protected def rows_changed
    @result.rows_changed
  end

  protected def duckdb_statement
    @statement.as(Statement)
  end

  def to_unsafe
    pointerof(@result)
  end

  private def check(state : LibDuckDB::State)
    unless state.success?
      message = if @result.error_message.null?
                  "Error with command `#{@statement.command}`"
                else
                  String.new(@result.error_message)
                end
      raise Exception.new(message)
    end
  end
end
