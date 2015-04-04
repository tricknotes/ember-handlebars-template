module Ember
  module Handlebars
    class Template < Tilt::Template
      include Helper

      class << self
        def configure
          yield config
        end

        def default_mime_type
          'application/javascript'
        end

        def setup(env)
          env.register_engine '.hbs', self
          env.register_engine '.handlebars', self
        end

        def config
          @config ||= Config.new
        end
      end

      def prepare; end

      def evaluate(scope, locals, &block)
        filename = scope.pathname.to_s

        raw = handlebars?(filename)

        if raw
          template = data
        else
          template = mustache_to_handlebars(filename, data)
        end

        if config.precompile
          if raw
            template = precompile_handlebars(template)
          else
            template = precompile_ember_handlebars(template, config.ember_template)
          end
        else
          if raw
            template = compile_handlebars(data)
          else
            template = compile_ember_handlebars(template, config.ember_template)
          end
        end

        case config.output_type
        when :amd
          target = amd_template_target(config.amd_namespace, scope.logical_path.split(".").first)

          "define('#{target}', ['exports'], function(__exports__){ __exports__['default'] = #{template} });"
        when :global
          target = global_template_target(scope.logical_path, config)

          "#{target} = #{template}\n"
        else
          raise "Unsupported `output_type`: #{config.output_type}"
        end
      end

      def config
        @config ||= self.class.config.dup
      end
    end
  end
end
