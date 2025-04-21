class Fibonaci

  # Generate a aficionado series up to
  def self.generate(max)
    # Start with the basic Fibonacci sequence
    last_fib = 1
    this_fib = 0
    result = []
    loop do
      return result if this_fib > max

      result << this_fib
      yield this_fib if block_given?
      last_fib, this_fib = this_fib, this_fib + last_fib
    end
  end
end

if $PROGRAM_NAME == __FILE__
  # Self test
  expected = [0]
  got = Fibonaci.generate(0)
  if expected == got
    puts "OK: Fibonacci.generate(0) = #{expected.inspect} as expected!"
  else
    puts "FAILED: Fibonacci.generate(100) = #{got.inspect}, expected: #{expected.inspect}!"
    exit(1)
  end
  expected = [0, 1, 1, 2, 3, 5, 8, 13, 21]
  got = Fibonaci.generate(21)
  if expected == got
    puts "OK: Fibonacci.generate(100) = #{expected.inspect} as expected!"
  else
    puts "FAILED: Fibonacci.generate(100) = #{got.inspect}, expected: #{expected.inspect}!"
    exit(1)
  end
  expected = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610]
  got = Fibonaci.generate(900)
  if expected == got
    puts "OK: Fibonacci.generate(100) = #{expected.inspect} as expected!"
  else
    puts "FAILED: Fibonacci.generate(100) = #{got.inspect}, expected: #{expected.inspect}!"
    exit(1)
  end
end
