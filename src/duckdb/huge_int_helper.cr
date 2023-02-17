module DuckDB
  module HugeIntHelper
    private FORMAT = IO::ByteFormat::BigEndian

    def self.huge_to_i128(value : LibDuckDB::HugeInt) : Int128
      aux_io = IO::Memory.new(16)
      aux_io.write_bytes(value.upper, FORMAT)
      aux_io.write_bytes(value.lower, FORMAT)
      aux_io.rewind
      Int128.from_io(aux_io, FORMAT)
    end

    def self.i128_to_huge(value : Int128) : LibDuckDB::HugeInt
      aux_io = IO::Memory.new(16)
      lower_io = IO::Memory.new(8)
      upper_io = IO::Memory.new(8)
      value.to_io(aux_io, FORMAT)
      aux_bytes = aux_io.to_slice
      upper_io.write(aux_bytes[0..7])
      lower_io.write(aux_bytes[8..15])
      upper_io.rewind
      lower_io.rewind
      result = LibDuckDB::HugeInt.new
      result.upper = Int64.from_io(upper_io, FORMAT)
      result.lower = UInt64.from_io(lower_io, FORMAT)
      result
    end
  end
end