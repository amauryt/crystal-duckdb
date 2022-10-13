module DuckDB
  @[Link("duckdb")]
  lib LibDuckDB
    alias CBool = UInt8

    alias Idx = UInt64
    type Database = Void*
    type Connection = Void*
    type PreparedStatement = Void*
    type Appender = Void*
    type Arrow = Void*
    type Config = Void*

    enum State
      Success = 0
      Error   = 1
    end

    # DuckDB data type.
    enum Type
      # Invalid data type.
      INVALID = 0
      # Treated as `Bool`.
      BOOLEAN
      # Treated as `Int8`.
      TINYINT
      # Treated as `Int16`.
      SMALLINT
      # Treated as `Int32`.
      INTEGER
      # Treated as `Int64`.
      BIGINT
      # Treated as `UInt8`.
      UTINYINT
      # Treated as `UInt16`.
      USMALLINT
      # Treated as `UInt32`.
      UINTEGER
      # Treated as `UInt64`.
      UBIGINT
      # Treated as `Float32`.
      FLOAT
      # Treated as `Float64`.
      DOUBLE
      # Treated as `Time`.
      TIMESTAMP
      # Treated as `DuckDB::Date`.
      DATE
      # Treated as `DuckDB::TimeOfDay`.
      TIME
      # duckdb_interval
      INTERVAL
      # Treated as `Int128`, if supported.
      HUGEINT
      # Treated as `String`.
      VARCHAR
      # Treated as `Bytes`.
      BLOB
      ## The following types are not used but are included for completeness
      DECIMAL
      TIMESTAMP_S
      TIMESTAMP_MS
      TIMESTAMP_NS
      ENUM
      LIST
      STRUCT
      MAP
      UUID
      JSON
    end


    struct Date
      # Days are stored as days since 1970-01-01
      days : Int32
    end

    struct Time
      # Time is stored as microseconds since 00:00:00
      micros : Int64
    end

    struct Timestamp
      # Time is stored as microseconds since 1970-01-01
      micros : Int64
    end

    struct Interval
      months : Int32
      days : Int32
      micros : Int64
    end

    struct HugeInt
      lower : UInt64
      upper : Int64
    end

    struct Decimal
      width : UInt8
      scale : UInt8
      value : HugeInt
    end

    struct Blob
      data : Void*
      size : Idx
    end

    struct Column
      data : Void*
      nullmask : CBool*
      type : Type
      name : LibC::Char*
      internal_data : Void*
    end

    struct Result
      column_count : Idx
      row_count : Idx
      rows_changed : Idx
      columns : Column*
      error_message : LibC::Char*
      internal_data : Void*
    end

    # # NOTE: ARROW FUNCTIONS NOT IMPLEMENTED

    # Opens a database file at the given path (nullptr for in-memory). Returns State::Success on success, or State::Error on
    # failure. [OUT: Database]
    fun open = duckdb_open(path : LibC::Char*, out_database : Database*) : State
    # Closes the database.
    fun close = duckdb_close(database : Database*) : Void

    # Extended version of duckdb_open. Creates a new database or opens an existing database file stored at the the given path.
    # configuration used to start up the database system
    # Returns State::Success on success, or State::Error on failure. [OUT: Database]
    fun open_ext = duckdb_open_ext(path : LibC::Char*, out_database : Database*, config : Config, out_error : LibC::Char**) : State

    # Creates a connection to the specified database. [OUT: connection]
    fun connect = duckdb_connect(database : Database, out_connection : Connection*) : State
    # Closes the specified connection handle
    fun disconnect = duckdb_disconnect(connection : Connection*) : Void


    # Initializes an empty configuration object that can be used to provide start-up options for the DuckDB instance
    # through `open_ext`
    fun create_config = duckdb_create_config(out_config : Config*) : State

    # Sets the specified option for the specified configuration. The configuration option is indicated by name.
    fun set_config = duckdb_set_config(config : Config, name : LibC::Char*, option : LibC::Char*) : State

    # Destroys the specified configuration option and de-allocates all memory allocated for the object.
    fun destroy_config = duckdb_destroy_config(config : Config*) : Void

    # Executes the specified SQL query in the specified connection handle. [OUT: result descriptor]
    fun query = duckdb_query(connection : Connection, query : LibC::Char*, out_result : Result*) : State
    # Destroys the specified result
    fun destroy_result = duckdb_destroy_result(result : Result*) : Void

    # Returns the column name of the specified column. The result does not need to be freed :
    # the column names will automatically be destroyed when the result is destroyed.
    fun column_name = duckdb_column_name(result : Result*, col : Idx) : LibC::Char*

    # Returns the column type of the specified column :
    # Returns `INVALID` if the column is out of range.
    fun column_type = duckdb_column_type(result : Result*, col : Idx) : Type

    # Returns the number of columns present in the result object.
    fun column_count = duckdb_column_count(result : Result*) : Idx

    # Returns the number of rows present in the result object.
    fun row_count = duckdb_row_count(result : Result*) : Idx

    # Returns the number of rows changed by the query stored in the result.
    # This is relevant only for INSERT/UPDATE/DELETE queries.
    # For other queries the rows_changed will be 0.
    fun rows_changed = duckdb_rows_changed(result : Result*) : Idx

    # Returns the error message contained within the result.
    # The error is only set if `duckdb_query` returns `DuckDBError`.
    fun result_error = duckdb_result_error(result : Result*) : LibC::Char*


    # # SAFE fetch functions
    # These functions will perform conversions if necessary. On failure (e.g. if conversion cannot be performed) a special
    # value is returned.

    # Converts the specified value to a bool. Returns false on failure or NULL.
    fun value_boolean = duckdb_value_boolean(result : Result*, col : Idx, row : Idx) : CBool
    # Converts the specified value to an int8_t. Returns 0 on failure or NULL.
    fun value_int8 = duckdb_value_int8(result : Result*, col : Idx, row : Idx) : Int8
    # Converts the specified value to an int16_t. Returns 0 on failure or NULL.
    fun value_int16 = duckdb_value_int16(result : Result*, col : Idx, row : Idx) : Int16
    # Converts the specified value to an int64_t. Returns 0 on failure or NULL.
    fun value_int32 = duckdb_value_int32(result : Result*, col : Idx, row : Idx) : Int32
    # Converts the specified value to an int64_t. Returns 0 on failure or NULL.
    fun value_int64 = duckdb_value_int64(result : Result*, col : Idx, row : Idx) : Int64
    # Converts the specified value to an uint8_t. Returns 0 on failure or NULL.
    fun value_uint8 = duckdb_value_uint8(result : Result*, col : Idx, row : Idx) : UInt8
    # Converts the specified value to an uint16_t. Returns 0 on failure or NULL.
    fun value_uint16 = duckdb_value_uint16(result : Result*, col : Idx, row : Idx) : UInt16
    # Converts the specified value to an uint64_t. Returns 0 on failure or NULL.
    fun value_uint32 = duckdb_value_uint32(result : Result*, col : Idx, row : Idx) : UInt32
    # Converts the specified value to an uint64_t. Returns 0 on failure or NULL.
    fun value_uint64 = duckdb_value_uint64(result : Result*, col : Idx, row : Idx) : UInt64
    # Converts the specified value to a float. Returns 0.0 on failure or NULL.
    fun value_float = duckdb_value_float(result : Result*, col : Idx, row : Idx) : Float32
    # Converts the specified value to a double. Returns 0.0 on failure or NULL.
    fun value_double = duckdb_value_double(result : Result*, col : Idx, row : Idx) : Float64
    # Converts the specified value to a date. Returns 0 on failure.
    fun value_date = duckdb_value_date(result : Result*, col : Idx, row : Idx) : Date
    # Converts the specified value to a time. Returns 0 on failure.
    fun value_time = duckdb_value_time(result : Result*, col : Idx, row : Idx) : Time
    # Converts the specified value to a timestamp. Returns 0 on failure.
    fun value_timestamp = duckdb_value_timestamp(result : Result*, col : Idx, row : Idx) : Timestamp
    # Converts the specified value to a interval. Returns 0 on failure.
    fun value_interval = duckdb_value_interval(result : Result*, col : Idx, row : Idx) : Interval
    # Converts the specified value to a string. Returns nullptr on failure or NULL. The result must be freed with `free`.
    fun value_varchar = duckdb_value_varchar(result : Result*, col : Idx, row : Idx) : LibC::Char*
    # Fetches a blob from a result set column. Returns a blob with blob.data set to nullptr on failure or NULL. The
    # resulting "blob.data" must be freed with duckdb_free.
    fun value_blob = duckdb_value_blob(result : Result*, col : Idx, row : Idx) : Blob
    # Returns true if the value at the specified index is NULL, and false otherwise.
    fun value_is_null = duckdb_value_is_null(result : Result*, col : Idx, row : Idx) : CBool

    # # Memory allocation

    # Allocate [size] amounts of memory using the duckdb internal malloc function. Any memory allocated in this manner
    # should be freed using duckdb_free
    fun malloc = duckdb_malloc(size : LibC::SizeT) : Void*
    # Free a value returned from `malloc`, `value_varchar` or `value_blob`
    fun free = duckdb_free(ptr : Void*) : Void

    # # Prepared Statements

    # prepares the specified SQL query in the specified connection handle. [OUT: prepared statement descriptor]
    fun prepare = duckdb_prepare(connection : Connection, query : LibC::Char*, out_prepared_statement : PreparedStatement*) : State
    fun prepare_error = duckdb_prepare_error(prepared_statement : PreparedStatement) : LibC::Char*
    fun nparams = duckdb_nparams(prepared_statement : PreparedStatement, nparams_out : Idx*) : State

    # binds parameters to prepared statement
    fun bind_boolean = duckdb_bind_boolean(prepared_statement : PreparedStatement, param_idx : Idx, val : CBool) : State
    fun bind_int8 = duckdb_bind_int8(prepared_statement : PreparedStatement, param_idx : Idx, val : Int8) : State
    fun bind_int16 = duckdb_bind_int16(prepared_statement : PreparedStatement, param_idx : Idx, val : Int16) : State
    fun bind_int32 = duckdb_bind_int32(prepared_statement : PreparedStatement, param_idx : Idx, val : Int32) : State
    fun bind_int64 = duckdb_bind_int64(prepared_statement : PreparedStatement, param_idx : Idx, val : Int64) : State
    fun bind_uint8 = duckdb_bind_uint8(prepared_statement : PreparedStatement, param_idx : Idx, val : UInt8) : State
    fun bind_uint16 = duckdb_bind_uint16(prepared_statement : PreparedStatement, param_idx : Idx, val : UInt16) : State
    fun bind_uint32 = duckdb_bind_uint32(prepared_statement : PreparedStatement, param_idx : Idx, val : UInt32) : State
    fun bind_uint64 = duckdb_bind_uint64(prepared_statement : PreparedStatement, param_idx : Idx, val : UInt64) : State
    fun bind_float = duckdb_bind_float(prepared_statement : PreparedStatement, param_idx : Idx, val : Float32) : State
    fun bind_double = duckdb_bind_double(prepared_statement : PreparedStatement, param_idx : Idx, val : Float64) : State
    fun bind_date = duckdb_bind_date(prepared_statement : PreparedStatement, param_idx : Idx, val : Date) : State
    fun bind_time = duckdb_bind_time(prepared_statement : PreparedStatement, param_idx : Idx, val : Time) : State
    fun bind_timestamp = duckdb_bind_timestamp(prepared_statement : PreparedStatement, param_idx : Idx, val : Timestamp) : State
    fun bind_interval = duckdb_bind_interval(prepared_statement : PreparedStatement, param_idx : Idx, val : Interval) : State
    fun bind_varchar = duckdb_bind_varchar(prepared_statement : PreparedStatement, param_idx : Idx, val : LibC::Char*) : State
    fun bind_varchar_length = duckdb_bind_varchar_length(prepared_statement : PreparedStatement, param_idx : Idx, val : LibC::Char*, length : Idx) : State
    fun bind_blob = duckdb_bind_blob(prepared_statement : PreparedStatement, param_idx : Idx, data : Void*, length : Idx) : State
    fun bind_null = duckdb_bind_null(prepared_statement : PreparedStatement, param_idx : Idx) : State

    # Executes the prepared statements with currently bound parameters
    fun execute_prepared = duckdb_execute_prepared(prepared_statement : PreparedStatement, out_result : Result*) : State

    # Destroys the specified prepared statement descriptor
    fun destroy_prepare = duckdb_destroy_prepare(prepared_statement : PreparedStatement*) : Void

    # # Appender
    fun appender_create = duckdb_appender_create(connection : Connection, schema : LibC::Char*, table : LibC::Char*, out_appender : Appender*) : State

    fun appender_begin_row = duckdb_appender_begin_row(appender : Appender) : State
    fun appender_end_row = duckdb_appender_end_row(appender : Appender) : State

    fun append_bool = duckdb_append_bool(appender : Appender, value : CBool) : State

    fun append_int8 = duckdb_append_int8(appender : Appender, value : Int8) : State
    fun append_int16 = duckdb_append_int16(appender : Appender, value : Int16) : State
    fun append_int32 = duckdb_append_int32(appender : Appender, value : Int32) : State
    fun append_int64 = duckdb_append_int64(appender : Appender, value : Int64) : State

    fun append_uint8 = duckdb_append_uint8(appender : Appender, value : UInt8) : State
    fun append_uint16 = duckdb_append_uint16(appender : Appender, value : UInt16) : State
    fun append_uint32 = duckdb_append_uint32(appender : Appender, value : UInt32) : State
    fun append_uint64 = duckdb_append_uint64(appender : Appender, value : UInt64) : State

    fun append_float = duckdb_append_float(appender : Appender, value : Float32) : State
    fun append_double = duckdb_append_double(appender : Appender, value : Float64) : State

    fun append_date = duckdb_append_date(appender : Appender, value : Date) : State
    fun append_time = duckdb_append_time(appender : Appender, value : Time) : State
    fun append_timestamp = duckdb_append_timestamp(appender : Appender, value : Timestamp) : State
    fun append_interval = duckdb_append_interval(appender : Appender, value : Interval) : State

    fun append_varchar = duckdb_append_varchar(appender : Appender, val : LibC::Char*) : State
    fun append_varchar_length = duckdb_append_varchar_length(appender : Appender, val : LibC::Char*, length : Idx) : State
    fun append_blob = duckdb_append_blob(appender : Appender, data : Void*, length : Idx) : State
    fun append_null = duckdb_append_null(appender : Appender) : State

    fun appender_flush = duckdb_appender_flush(appender : Appender) : State
    fun appender_close = duckdb_appender_close(appender : Appender) : State

    fun appender_destroy = duckdb_appender_destroy(appender : Appender*) : State
  end
end
