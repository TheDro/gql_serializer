

module GqlSerializer
  class Configuration
    CAMEL_CASE = :camel
    SNAKE_CASE = :snake
    NONE_CASE = :none
    SUPPORTED_CASES = [CAMEL_CASE, SNAKE_CASE, NONE_CASE]

    def initialize
      @case = NONE_CASE
    end

    attr_reader :case

    def case=(value)
      raise "Specified case '#{value}' is not supported" unless SUPPORTED_CASES.include?(value)
      @case = value
    end

    def to_h
      {case: @case}
    end
  end
end