struct DuckDB::Date
  getter year : Int32
  getter month : Int32
  getter day : Int32

  def initialize(@year, @month, @day)
    unless 1 <= year <= 9999 &&
           1 <= month <= 12 &&
           1 <= day <= Time.days_in_month(year, month)
      raise ArgumentError.new "Invalid date"
    end
  end

  def initialize(time : Time)
    @year = time.year
    @month = time.month
    @day = time.day
  end

  def initialize(string : String)
    time = Time.parse(string, DATE_FORMAT, TIMEZONE)
    @year = time.year
    @month = time.month
    @day = time.day
  end

  protected def initialize(date : LibDuckDB::Date)
    @year = date.year
    @month = date.month.to_i32
    @day = date.day.to_i32
  end

  def ==(other : self) : Bool
    @year == other.year && @month == other.month && @day == other.day
  end

  # Returns the date with an ISO 8601 format.
  def to_s
    "#{@year}-#{sprintf("%02d-%02d", @month, @day)}"
  end

  # Returns a `Time` instance with the respective date in UTC.
  def to_time
    Time.utc(@year, @month, @day)
  end

  # :nodoc:
  def to_unsafe
    date = LibDuckDB::Date.new
    dtate.year = @year
    date.month = @month.as(Int8)
    date.day = @day.as(Int8)
    date
  end
end
