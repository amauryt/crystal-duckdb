# crystal-duckdb

[![Crystal CI](https://github.com/amauryt/crystal-duckdb/actions/workflows/crystal.yml/badge.svg)](https://github.com/amauryt/crystal-duckdb/actions/workflows/crystal.yml)

Crystal bindings for [DuckDB](https://duckdb.org/), an in-process SQL OLAP database management system.

Check [crystal-db](https://github.com/crystal-lang/crystal-db) for general DB driver documentation. This shard's driver is registered under the `duckdb://` URI.

## Project status

This is an implementation primarily intended to fulfill my needs for Online Analytical Processing (OLAP) using DuckDB across different languages (Crystal, R, and JS). Therefore, only a subset of the DuckDB C API is implemented, but **it should more than enough for many OLAP applications in Crystal**.

Please note that OLAP workloads and workflows are very different from OLTP (Online Transaction Processing), especially in an embedded context. Before using DuckDB be sure to understand the differences between the two to decide which option is more apt for your use case.

## DuckDB compatibility

DuckDB is a relatively young but highly exciting project. However, a stable version is yet to be reached and in the meantime **breaking changes are expected**. Be sure to use the correct shard version and to consult the respective README file for your version of the DuckDB engine. In addition, there might be DB file *storage incompability* across different versions of DuckDB engines, in this case you need to export your data with the old engine and import it with the new engine; see the [export/import documentation](https://duckdb.org/docs/sql/statements/export) for more details. If supported I suggest using the parquet format.

| Shard release   | DuckDB engine    | Notes                                                 |
| --------------- | -----------------| ------------------------------------------------------|
| 0.2.5           |  0.9.x – 0.10.x  | Storage compability. Updated `crystal-db` to v0.13.   |
| 0.2.4           |  0.9.x – 0.10.x  | Storage incompability. Updated `crystal-db` to v0.12. |
| 0.2.3           |  0.6.0 – 0.8.x   | Added support for hugeint. Changed varchar C API.     |
| 0.2.2           |  0.5.1 – 0.6.0   | Added support for interval datatype and configuration.|
| 0.2.1           |  0.3.4 – 0.5.1   | Storage incompability. Updated `crystal-db` to v0.11. |
| 0.2.0           |  0.2.9 – 0.3.2   | Storage incompability.                                |
| 0.1.x           |  0.2.8           |                                                       |


## Prerequisites

You must have a **compatible DuckDB engine** installed and available as a dynamic library within your app.

For MacOS (and many Linux distributions) the simplest way to install DuckDB is via homebrew:

```
brew install duckdb
```

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     duckdb:
       github: amauryt/crystal-duckdb
       version: ~> 0.2.5
   ```

2. Run `shards install`

## Usage

For most use cases it is better to use the connection directly instead of a DB pool.

```crystal
require "duckdb"

DB.connect "duckdb://./data.db" do |cnn|
  cnn.exec "create table contacts (name varchar, age integer)"
  cnn.exec "insert into contacts values (?, ?)", "John Doe", 30

  args = [] of DB::Any
  args << "Sarah"
  args << 33
  cnn.exec "insert into contacts values (?, ?)", args: args

  puts "max age:"
  puts cnn.scalar "select max(age) from contacts" # => 33

  puts "contacts:"
  cnn.query "select name, age from contacts order by age desc" do |rs|
    puts "#{rs.column_name(0)} (#{rs.column_name(1)})"
    # => name (age)
    rs.each do
      puts "#{rs.read(String)} (#{rs.read(Int32)})"
      # => Sarah (33)
      # => John Doe (30)
    end
  end
end
```

For an in-memory database you can use `DuckDB::IN_MEMORY`. 

```crystal
require "duckdb"

DB.connect DuckDB::IN_MEMORY do |cnn|
  cnn.scalar("select 'hello world'") # => "hello world"
end
```

### Configuration

You can also modify the DuckDB configuration upon opening a database using URI params (together with the URI params available from `crystal-db`).

For more details refer to the [DuckDB configuration documentation](https://duckdb.org/docs/sql/configuration).

Beware that an invalid configuration will raise a `DuckDB::Exception`.

```crystal
require "duckdb"

# Connect to a database in read-only mode (file must already exists) and with NULL values ordered last by default
DB.connect "duckdb://./data.db?access_mode=read_only&default_null_order=nulls_last" do |cnn|
  puts cnn.scalar "SELECT current_setting('access_mode')"  # => read_only
  puts cnn.scalar "SELECT current_setting('default_null_order')"  # => nulls_last
end
```

To configure an in-memory database:

```crystal
require "duckdb"
DB.connect "#{DuckDB::IN_MEMORY}?default_null_order=nulls_last" do |cnn|
  puts cnn.scalar "SELECT current_setting('default_null_order')"  # => nulls_last
end
```

### Appender

To efficiently load bulk data into a table use the appender instead of insert statements.
The [Appender](https://duckdb.org/docs/api/c/appender) is tied to a connection, and will use the transaction context of that connection when appending.
An Appender always appends to a single table in the database.

```crystal
require "duckdb"

records = [
  {name: "Alice", age: 20, is_active: true},
  {name: "Bob", age: 30, is_active: false}
  {name: "Charles", age: 25, is_active: nil}
]

DB.connect DuckDB::IN_MEMORY do |cnn|
  cnn.exec "create table contacts (name varchar, age integer, is_active boolean)"

  cnn.appender("contacts") do |appender|
    records.each do |record|
      appender.row do |row|
        row << record.name
        row << record.age
        row << record.is_active
      end
    end
  end 
end
```

## Implemented datatypes

The following DuckDB [SQL datatypes](https://duckdb.org/docs/sql/data_types/overview) plus 'NULL' are supported:

| Crystal             | SQL Datatype        |
| ------------------- | ------------------- |
| `Nil`               | NULL                |
| `Bool`              | BOOLEAN             |
| `Int8`              | TINYINT             |
| `Int16`             | SMALLINT            |
| `Int32`             | INTEGER             |
| `Int64`             | BIGINT              |
| `Int128`            | HUGEINT             |
| `UInt8`             | UTINYINT            |
| `UInt16`            | USMALLINT           |
| `UInt32`            | UINTEGER            |
| `UInt64`            | UBIGINT             |
| `Float32`           | FLOAT               |
| `Float64`           | DOUBLE              |
| `String`            | VARCHAR             |
| `Bytes`             | BLOB                |
| `DuckDB::Date`      | DATE                |
| `DuckDB::TimeOfDay` | TIME                |
| `DuckDB::Timestamp` | TIMESTAMP           |
| `DuckDB::Interval`  | INTERVAL            |


All other DuckDB SQL datatypes are treated as `String`.

You can also use `DuckDB::Any`, which augments `DB::Any` according to the table above.

### Time-related datatypes

Given the differences between time-related standard Crystal structs and DuckDB SQL datatypes, this shard implements lightweight Crystal structs to better interact with DuckDB.

Please note the following:

* As DuckDB does not support timezones without an extension, all Crystal's `Time` instances **must be in UTC**
* Crystal's `Time` and `Time::Span` resolutions are in nanoseconds while DuckDB's 'TIME' is in microseconds, thus beware of **loss of precision while converting between structs** (where integer division is used)
* Creating a new `DuckDB::TimeOfDay` from a `Time::Span` greater or equal than a day raises a `DuckDB::Exception`
* Converting a `DuckDB::Interval` with a non-zero month value to `Time::Span` without specifying the number of days per month raises a `DuckDB::Exception`

```crystal
require "duckdb"

time = Time.utc(1999, 12, 31, 10, 11, 59)

date = DuckDB::Date.new(1999, 12, 31)
date.year   # => 1999
date.month  # => 12
date.day    # => 31
date.to_s   # => "1999-12-31"
date == DuckDB::Date.new("1999-12-31")  # => true
date == DuckDB::Date.new(time)          # => true
date.to_time == time                    # => false

time_of_day = DuckDB::TimeOfDay.new(10, 11, 59)
time_of_day.hour        # => 10
time_of_day.minute      # => 11
time_of_day.second      # => 59
time_of_day.microsecond # => 0
time_of_day.to_s        # => "10:11:59"
span = time_of_day.to_span
time_of_day == DuckDB::TimeOfDay.new("10:11:59")  # => true
time_of_day == DuckDB::TimeOfDay.new(time)        # => true
time_of_day == DuckDB::TimeOfDay.new(span)        # => true

timestamp = DuckDB::Timestamp.new(date, time_of_day)
timestamp.date        # => <DuckDB::Date>
timestamp.time_of_day # => <DuckDB::TimeOfDay>
timestamp.to_span     # => <Time::Span>
time_of_day == DuckDB::Timestamp.new("1999-12-31 10:11:59") # => true
timestamp == DuckDB::Timestamp.new(time)                    # => true
timestamp.to_time == time                                   # => true
# Expected getters are delegated to date and time of_day
timestamp.year # => 1999
timestamp.hour # => 10

interval = DuckDB::Interval.new(0, 1, 2)
interval.months # => 2
interval.days # => 1
interval.microseconds # => 0
# non-zero value for months; must indicate days per month while converting to Time::Span
interval.to_span(30) # => 61.00:00:00
interval.to_span(31) # => 63.00:00:00
interval.to_span(0) # => 1.00:00:00
interval.to_month_span # => Time::MonthSpan(@value=2)
interval.to_spans # => {1.00:00:00, Time::MonthSpan(@value=2)}
```

For covenience you can also use `Time` to read from a result set, and a `Time` instance (in UTC) to bind to a prepared statement or append to a row; in this case it is automatically converted to `DuckDB::Timestamp`. However, when only reading a timestamp scalar you should use `#to_time` after reading the value in order to get a `Time` instance.

```crystal
require "duckdb"

DB.connect DuckDB::IN_MEMORY do |cnn|
  cnn.exec "create table events (id integer, at timestamp)"

  cnn.exec "insert into events values (?, ?)", 1, Time::UNIX_EPOCH

  cnn.appender("contacts") do |appender|
    appender.row do |row|
      row << 2
      row << Time.utc
    end
  end

  cnn.query "select * from events" do |rs|
    rs.each do
      id = rs.read(Int32)
      at = rs.read(Time)
    end
  end

  timestamp = cnn.scalar "select at from event where id = 1"
  timestamp.to_time == Time::UNIX_EPOCH # => true
end
```

## Known issues

* DuckDB v0.3.3 was a short-lived version —with v0.3.4 being a bug fix relase for it— hence there is no corresponding shard version.

* For DuckDB v0.2.8 binding `UInt8` and `UInt16` values to prepared statements causes a crash due to a typo in the C header file. This is already fixed for later versions. See [this issue](https://github.com/duckdb/duckdb/issues/2105) for more information.


## Contributing

1. Fork it (<https://github.com/your-github-user/crystal-duckdb/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Be sure to run the specs with `crystal spec` before commiting and, if necessary, add the related specs for your new feature or change.

## Contributors

- [Amaury Trujillo](https://github.com/amauryt) - creator and maintainer
