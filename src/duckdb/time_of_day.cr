# Represents the TIME data type of SQL within DuckDB.
#
struct DuckDB::TimeOfDay
  getter hour : Int32
  getter minute : Int32
  getter second : Int32
  getter microsecond : Int32

  def initialize(@hour, @minute, @second = 0, @microsecond = 0)
    if @hour < 0 || @hour > 24 || @minute < 0 || @minute > 60 || @minute < 0 || @minute > 60 || @second < 0 || @second > 60 || @microsecond < 0 || @microsecond > 1_000_000
      raise ArgumentError.new("Invalid time of day values.")
    end
  end

  # NOTE: It raises `ArgumentError` if `time` is not in UTC.
  # NOTE: Beware the loss of precision in the fractional part (nanoseconds to microseconds)
  def initialize(time : Time)
    raise ArgumentError.new("Time is not in UTC") unless time.utc?

    @hour = time.hour
    @minute = time.minute
    @second = time.second
    @microsecond = time.nanosecond // 1000
  end

  # NOTE: It raises `ArgumentError` unless `span` is less than one day.
  # NOTE: Beware of loss of precision for the fractional part (nanoseconds to microseconds).
  def initialize(span : Time::Span)
    raise ArgumentError.new("Time span must have less than one day of duration.") if span.days >= 1
    @hour = span.hours
    @minute = span.minutes
    @second = span.seconds
    @microsecond = span.nanoseconds // 1000
  end

  def initialize(string : String)
    format = string.includes?(".") ? DuckDB::TIME_OF_DAY_FORMAT_SUBSECOND : DuckDB::TIME_OF_DAY_FORMAT_SECOND
    time = Time.parse(string, format, DuckDB::TIMEZONE)
    @hour = time.hour
    @minute = time.minute
    @second = time.second
    @microsecond = time.nanosecond // 1000
  end

  protected def initialize(time : LibDuckDB::Time)
    @hour = time.hour.to_i32
    @minute = time.min.to_i32
    @second = time.sec.to_i32
    @microsecond = time.micros.to_i32
  end

  def millisecond
    microsecond // 1000
  end

  def subsecond?
    @microsecond > 0
  end

  def submillisecond?
    @microsecond < 1000
  end

  def ==(other : self) : Bool
    @hour == other.hour && @minute == other.minute && @second == other.second && @microsecond == other.microsecond
  end

  def to_s
    String.build(16) do |str|
      str << sprintf("%02d:%02d:%02d", @hour, @minute, @second)
      str << sprintf(".%06d", @microsecond).gsub(/0+$/, "") unless @microsecond.zero?
    end
  end

  def to_span : Time::Span
    nanosecond = @microsecond * 1000
    Time::Span.new(hours: @hour, minutes: @minute, seconds: @second, nanoseconds: nanosecond)
  end

  # :nodoc:
  def to_unsafe
    time = LibDuckDB::Time.new
    time.hour = @hour.as(Int8)
    time.min = @minute.as(Int8)
    time.sec = @second.as(Int8)
    time.micros = @microsecond.as(Int16)
    time
  end
end
