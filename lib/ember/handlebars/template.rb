require 'sprockets'
require 'barber'

module Ember
  module Handlebars
    autoload :VERSION, 'ember/handlebars/version'
    autoload :Config, 'ember/handlebars/config'
    autoload :Helper, 'ember/handlebars/helper'

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
          env.register_engine '.hjs', self, mime_type: 'application/javascript'
          env.register_engine '.handlebars', self, mime_type: 'application/javascript'
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
            template = precompile_ember_handlebars(template, config.ember_template, input)
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
          target = amd_template_target(config.amd_namespace, actual_name(input))

          "define('#{target}', ['exports'], function(__exports__){ __exports__['default'] = #{template} });"
        when :global
          target = global_template_target(actual_name(input), config)

          "#{target} = #{template}\n"
        else
          raise "Unsupported `output_type`: #{config.output_type}"
        end
      end

      private

      def precompile_handlebars(template, input)
        dependencies = [
          Barber::Precompiler.compiler_version,
          template,
        ]

        input[:cache].fetch(_cache_key + dependencies) do
          super(template)
        end
      end

      def precompile_ember_handlebars(template, ember_template, input)
        dependencies = [
          Barber::Ember::Precompiler.compiler_version,
          ember_template,
          template
        ]

        input[:cache].fetch(_cache_key + dependencies) do
          super(template, ember_template)
        end
      end

      def _cache_key
        [
          self.class.name,
          VERSION,
          Barber::VERSION
        ]
      end

      def actual_name(input)
        actual_name = input[:name]

        if input[:filename][File.expand_path(input[:name] + '/index', input[:load_path])]
          if actual_name == '.'
            actual_name = 'index'
          else
            actual_name += '/index'
          end
        end

        actual_name
      end
    end
  end
end
