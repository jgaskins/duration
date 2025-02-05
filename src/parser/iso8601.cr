struct Duration
  # The `ISO8601` parser is an incredibly efficient, zero-allocation [ISO8601
  # duration](https://en.wikipedia.org/wiki/ISO_8601#Durations) parser. It
  # parses strings like `"P3Y6M4DT12H30M5S"` into `Duration` instances.
  #
  # ```
  # # 3 years, 6 months, 4 days, 12 hours, 30 minutes, 5.5 seconds
  # Duration.parse_iso8601("P3Y6M4DT12H30M5.5S")
  # # => Duration(@months=42, @days=4, @nanoseconds=45005500000000)
  # ```
  struct Parser::ISO8601
    def parse(string : String)
      in_time = false
      years = 0
      months = 0
      weeks = 0
      days = 0
      hours = 0i64
      minutes = 0i64
      seconds = 0i64
      nanoseconds = 0i64

      # Accumulators
      var : Int64 = 0_i64      # accumulates the integer part
      fraction : Float64 = 0.0 # accumulates the fractional part, if any
      in_fraction = false      # flag to indicate we are parsing the fraction part
      fraction_div = 1.0       # used to divide each fraction digit

      # Iterate over the string starting after the initial 'P'
      i = 1
      while i < string.bytesize
        c = string.to_slice[i]
        i += 1

        case c
        when '0'.ord..'9'.ord
          # Process a digit (character codes for '0'..'9')
          d = c - '0'.ord
          if !in_fraction
            var = var * 10 + d
          else
            fraction_div *= 10.0
            fraction += d.to_f64 / fraction_div
          end
        when '.'
          # A period signals the start of a fraction
          if in_fraction
            raise ArgumentError.new("Invalid ISO8601 duration: multiple decimal points in a number")
          end
          in_fraction = true
        when 'T'
          # The 'T' indicates that time components follow.
          in_time = true
          # Reset the accumulator (it must not carry over)
          var = 0
          fraction = 0.0
          in_fraction = false
          fraction_div = 1.0
        when 'Y'
          # Years (only allowed in the date portion)
          if in_fraction
            raise ArgumentError.new("Invalid ISO8601 duration: fractional years not allowed")
          end
          years = var.to_i32
          var = 0; fraction = 0.0; in_fraction = false; fraction_div = 1.0
        when 'M'
          # 'M' is ambiguous: if before 'T' it means months; after 'T' it means minutes.
          if in_time
            if in_fraction
              raise ArgumentError.new("Invalid ISO8601 duration: fractional minutes not allowed")
            end
            minutes = var
          else
            if in_fraction
              raise ArgumentError.new("Invalid ISO8601 duration: fractional months not allowed")
            end
            months = var.to_i32
          end
          var = 0; fraction = 0.0; in_fraction = false; fraction_div = 1.0
        when 'W'
          if in_fraction
            raise ArgumentError.new("Invalid ISO8601 duration: fractional weeks not allowed")
          end
          weeks = var.to_i32
          var = 0; fraction = 0.0; in_fraction = false; fraction_div = 1.0
        when 'D'
          if in_fraction
            raise ArgumentError.new("Invalid ISO8601 duration: fractional days not allowed")
          end
          days = var.to_i32
          var = 0; fraction = 0.0; in_fraction = false; fraction_div = 1.0
        when 'H'
          if in_fraction
            raise ArgumentError.new("Invalid ISO8601 duration: fractional hours not allowed")
          end
          hours = var
          var = 0; fraction = 0.0; in_fraction = false; fraction_div = 1.0
        when 'S'
          # Seconds may be fractional.
          tot = var.to_f64 + fraction
          seconds = var.to_i64
          nanoseconds = (fraction * 1_000_000_000).to_i64
          var = 0; fraction = 0.0; in_fraction = false; fraction_div = 1.0
        else
          raise ArgumentError.new("Invalid character '#{c.chr}' in ISO8601 duration")
        end
      end

      Duration.new(
        years: years,
        weeks: weeks,
        months: months,
        days: days,
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        nanoseconds: nanoseconds,
      )
    end
  end
end
