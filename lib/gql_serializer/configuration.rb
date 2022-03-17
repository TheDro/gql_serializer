

module GqlSerializer
  class Configuration
    CAMEL_CASE = :camel
    SNAKE_CASE = :snake
    NONE_CASE = :none
    SUPPORTED_CASES = [CAMEL_CASE, SNAKE_CASE, NONE_CASE]

    def initialize
      reset
    end

    attr_reader :case, :preload

    def case=(value)
      raise "Specified case '#{value}' is not supported" unless SUPPORTED_CASES.include?(value)
      @case = value
    end

    def reset
      @case = NONE_CASE
      @preload = false # Default will be true in version 3+
    end

    def to_h
      {case: @case}
    end
  end
end