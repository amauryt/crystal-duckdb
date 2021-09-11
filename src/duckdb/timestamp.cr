struct DuckDB::Timestamp
  getter date : Date
  getter time_of_day : TimeOfDay

  delegate year, to: @date
  delegate month, to: @date
  delegate day, to: @date
  delegate hour, to: @time_of_day
  delegate minute, to: @time_of_day
  delegate second, to: @time_of_day
  delegate millisecond, to: @time_of_day
  delegate microsecond, to: @time_of_day
  delegate subsecond?, to: @time_of_day
  delegate submillisecond?, to: @time_of_day

  def initialize(@date, @time_of_day)
  end

  # Initializes a timestamp with a `Time` instance in UTC.
  #
  # It raises `ArgumentError` if `time` is not in UTC.
  # NOTE: Beware the loss of precision in the fractional part (nanoseconds to microseconds)
  def initialize(time : Time)
    raise ArgumentError.new("Time is not in UTC") unless time.utc?

    @date = Date.new(time.year, time.month, time.day)
    @time_of_day = TimeOfDay.new(time.hour, time.minute, time.second, time.nanosecond // 1000)
  end

  def initialize(string : String)
    strings = string.split(" ")
    @date = Date.new(strings[0])
    @time_of_day = TimeOfDay.new(strings[1])
  end

  # Initialize with microseconds since `Time::UNIX_EPOCH`
  def initialize(microseconds : Int64)
    span = Time::Span.new(nanoseconds: microseconds * 1000)
    time = Time::UNIX_EPOCH + span
    @date = Date.new(time)
    @time_of_day = TimeOfDay.new(time)
  end

  def ==(other : self) : Bool
    @date == other.date && @time_of_day == other.time_of_day
  end

  # Returns the timestamp with an ISO 8601 format.
  def to_s
    "#{@date.to_s} #{@time_of_day.to_s}"
  end

  # Returns a `Time` instance with the respective timestamp in UTC.
  def to_time
    Time.utc(
      @date.year,
      @date.month,
      @date.day,
      @time_of_day.hour,
      @time_of_day.minute,
      @time_of_day.second,
      nanosecond: @time_of_day.microsecond * 1000
    )
  end

  # :nodoc:
  def to_unsafe
    timestamp = LibDuckDB::Timestamp.new
    timestamp.micros = (self.to_time - Time::UNIX_EPOCH).total_microseconds.to_i64
    timestamp
  end
end
