module Spatch
  class IssueDeck
    @issues : Hash(Symbol, Array(String))
    @field : Symbol

    def initialize
      @issues = Hash(Symbol, Array(String)).new
      @field = :unknown
    end

    def add(field : Symbol, message : String)
      @issues[field] = Array(String).new unless @issues[field]?
      @issues[field] << message
    end

    def add(message : String)
      self.add(@field, message)
    end

    def set_field(field : Symbol)
      self.tap { |s| @field = field }
    end

    def empty? : Bool
      @issues.empty?
    end

    def expose : Hash(Symbol, Array(String))
      @issues
    end

  end
end
