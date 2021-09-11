# crystal-duckdb

[![Crystal CI](https://github.com/amauryt/crystal-duckdb/actions/workflows/crystal.yml/badge.svg)](https://github.com/amauryt/crystal-duckdb/actions/workflows/crystal.yml)

Crystal bindings for [DuckDB](https://duckdb.org/), an in-process SQL OLAP database management system.

Check [crystal-db](https://github.com/crystal-lang/crystal-db) for general DB driver documentation. This shard's driver is registered under the `duckdb://` URI.

## Project status

This is an initial implementation primarily intended to fulfill my needs for Online Analytical Processing (OLAP) using DuckDB. My main use case is to efficiently transfer values from Crystal, via the append functionality of DuckDB, in order to populate a larger-than-memory database with which to do exploratory data analysis in [R](https://www.r-project.org/). Obviously this could be also be extended to Python or any other language with a DuckDB client. Therefore, at the moment it only a subset of the DuckDB C API is implemented, but it should enough for many OLAP applications in Crystal.

Please note that OLAP workloads and workflows are very different from OLTP (Online Transaction Processing), especially in an embedded context. Before using DuckDB be sure to understand the differences between the two to decide which option is more apt for your use case.

Finally, take into consideration that DuckDB is a relatively young but highly exciting project. A stable version is yet to be reached and in the meantime **breaking changes are expected**.

## Prerequisites

You must have the **DuckDB engine v0.2.8** installed and available as a dynamic library within your app.

For MacOS the simplest way to install DuckDB is via homebrew:

```
brew install duckdb
```

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     duckdb:
       github: amauryt/crystal-duckdb
       version: ~> 0.1.0
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

For an in-memory database:

```crystal
require "duckdb"

DB.connect DuckDB::IN_MEMORY do |cnn|
  cnn.scalar("select 'hello world'") # => "hello world"
end
```

### Appender

To efficiently load bulk data a table use the appender instead of insert statements.
The [Appender](https://duckdb.org/docs/data/appender) is tied to a connection, and will use the transaction context of that connection when appending.
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


All other DuckDB SQL datatypes are treated as `String`.

You can also use `DuckDB::Any`, which augments `DB::Any` according to the table above.

### Time-related datatypes

Given the differences between time-related standard Crystal structs and DuckDB SQL datatypes, this shard implements lightweight Crystal structs to better interact with DuckDB.

Please note the following:

* As DuckDB does not support timezones, all Crystal's `Time` instances **must be in UTC**
* Crystal's `Time` and `Time::Span` resolutions are in nanoseconds while DuckDB's 'TIME' is in microseconds, thus beware of **loss of precision while converting between structs** (where integer division is used)
* Creating a new `DuckDB::TimeOfDay` from a `Time::Span` greater or equal than a day raises `DuckDB::Exception`

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

For DuckDB v0.2.8 binding `UInt8` and `UInt16` values to prepared statements causes a crash due to a typo in the C header file. This is already fixed for later versions. See [this issue](https://github.com/duckdb/duckdb/issues/2105) for more information.

## Contributing

1. Fork it (<https://github.com/your-github-user/crystal-duckdb/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Amaury Trujillo](https://github.com/amauryt) - creator and maintainer
