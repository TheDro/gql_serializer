

module GqlSerializer
  class Configuration
    CAMEL_CASE = :camel
    SNAKE_CASE = :snake
    NONE_CASE = :none
    SUPPORTED_CASES = [CAMEL_CASE, SNAKE_CASE, NONE_CASE]

    def initialize
      reset
    end

    attr_accessor :case, :preload

    def case=(value)
      raise "Specified case '#{value}' is not supported" unless SUPPORTED_CASES.include?(value)
      @case = value
    end

    def reset
      @case = NONE_CASE
      @preload = true
    end

    def to_h
      self.instance_values.symbolize_keys
    end
  end
end