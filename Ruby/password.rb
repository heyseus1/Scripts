#!/usr/bin/env ruby
# Random alphanumeric password generator
# Takes one parameter, which is the password length
# Forces the minimum length to be 10 or more


CHARS = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a + ('!'..'+').to_a
class << CHARS
	def rand
		self[Kernel.rand(size)]
	end
end
len = ARGV.first.to_i
len = 32 unless len > 0
len.times { print CHARS.rand}
puts

