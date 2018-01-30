module Spatch
  abstract struct Task

    @issues : Spatch::IssueDeck

    def initialize
      @issues = Spatch::IssueDeck.new
    end

    protected def issue_deck : Spatch::IssueDeck
      @issues
    end

    abstract def perform

    macro input(type_decl)
      {% INPUTS << type_decl %}
      @{{type_decl.var.id}} : {{type_decl.type.id}}
    end

    macro output(type_decl)
      {% OUTPUTS << type_decl %}
      @{{type_decl.var.id}} : Union({{type_decl.type.id}}, Nil)

      protected def {{type_decl.var.id}} : Union({{type_decl.type.id}}, Nil)
        @{{type_decl.var.id}}
      end
    end

    macro inherited

      INPUTS = [] of Nil
      OUTPUTS = [] of Nil

      @@total_run_calls = 0_u64
      @@total_runtime = Time::Span.zero

      def self.total_run_calls
        @@total_run_calls
      end

      def self.total_runtime : Time::Span
        @@total_runtime
      end

      def self.average_runtime : Time::Span
        @@total_runtime / @@total_run_calls
      end

      macro finished

        struct Summary < Spatch::Summary

          \{% for t in OUTPUTS %}
            @\{{t.var.id}} : Union(\{{t.type.id}}, Nil)
            
            def \{{t.var.id}} : \{{t.type.id}}
              raise "Cannot retrieve outputs from failed task" unless self.successful?
              @\{{t.var.id}}.as(\{{t.type.id}})
            end
          \{% end %}

          def initialize(began_at : Time, runtime : Time::Span, issues : Hash(Symbol, Array(String)), \{% for t in OUTPUTS %} \{{t.var.id}} : Union(\{{t.type.id}}, Nil) = nil, \{% end %})
            \{% for t in OUTPUTS %}
              @\{{t.var.id}} = \{{t.var.id}}
            \{% end %}
            super(began_at, runtime, issues)
          end

        end

        protected def validate_inputs
          \{% for t in INPUTS %}
            \{% if @type.has_method? ("validate_" + t.var.id.stringify).id %}
              @issues.set_field \{{t.var.symbolize}}
              self.validate_\{{t.var.id}}
            \{% end %}
          \{% end %}
        end

        protected def initialize(\{% for t in INPUTS %} \{{t.var.id}} : \{{t.type.id}}, \{% end %})
          \{% for t in INPUTS %}
            @\{{t.var.id}} = \{{t.var.id}}
          \{% end %}
          super()
        end

        def self.run(\{% for t in INPUTS %} \{{t.var.id}} : \{{t.type.id}}, \{% end %}) : Summary
          @@total_run_calls += 1
          began_at = Time.now
          clock = Time.monotonic
          task = \{{@type}}.new(\{% for t in INPUTS %} \{{t.var.id}}: \{{t.var.id}}, \{% end %})
          task.validate_inputs
          if task.issue_deck.empty?
            begin
              task.perform
            rescue ex
              task.issue_deck.add :perform, ex.to_s
            end
          end
          runtime = Time.monotonic - clock
          @@total_runtime += runtime
          summary_params = {
            \{% for t in OUTPUTS %}
              \{{t.var.id}}: task.try &.\{{t.var.id}},
            \{% end %}
            began_at: began_at,
            runtime: runtime,
            issues: task.issue_deck.expose
          }
          Summary.new(**summary_params)
        end

      end
    end
  end
end
