module Spatch
  abstract struct Summary

    @began_at : Time
    @runtime : Time::Span
    @issues : Hash(Symbol, Array(String))

    def initialize(began_at : Time, runtime : Time::Span, issues : Hash(Symbol, Array(String)))
      @began_at = began_at
      @runtime = runtime
      @issues = issues
    end

    def successful? : Bool
      @issues.empty?
    end

    def began_at : Time
      @began_at
    end

    def finished_at : Time
      @began_at + @runtime
    end

    def runtime : Time::Span
      @runtime
    end

    def issues
      @issues
    end
  end
end
