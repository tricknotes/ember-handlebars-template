module Ember
  module Handlebars
    class Template
      include Helper

      class << self
        def configure
          yield config
        end

        def config
          @config ||= Config.new
        end

        def setup(env)
          env.register_engine '.hbs', self, mime_type: 'application/javascript'
        end

        def instance
          @instance ||= new(config)
        end

        def call(input)
          instance.call(input)
        end
      end

      attr_reader :config

      def initialize(config = self.class.config.dup)
        @config = config
      end

      def call(input)
        input[:cache].fetch(cache_key + [input[:data]]) { _call(input) }
      end

      def _call(input)
        data = input[:data]
        filename = input[:filename]

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
          target = amd_template_target(config.amd_namespace, input[:name])

          "define('#{target}', ['exports'], function(__exports__){ __exports__['default'] = #{template} });"
        when :global
          target = global_template_target(input[:name], config)

          "#{target} = #{template}\n"
        else
          raise "Unsupported `output_type`: #{config.output_type}"
        end
      end

      def cache_key
        [
          self.class.name,
          VERSION,
          config.to_hash
        ]
      end
    end
  end
end
