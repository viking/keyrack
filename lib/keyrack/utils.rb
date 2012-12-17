module Keyrack
  module Utils
    def self.generate_password
      result = "        "
      result.length.times do |i|
        result[i] = (33 + rand(94)).chr
      end
      result
    end
  end
end
