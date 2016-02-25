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
          env.register_mime_type 'text/x-handlebars', extensions: %w(.raw.hbs .raw.hjs .raw.handlebars)
          env.register_transformer 'text/x-handlebars', 'application/javascript', self

          env.register_mime_type 'text/x-ember-mustache', extensions: %w(.mustache.hbs .mustache.hjs .mustache.handlebars)
          env.register_transformer 'text/x-ember-mustache', 'application/javascript', self

          env.register_mime_type 'text/x-ember-handlebars', extensions: %w(.hbs .hjs .handlebars)
          env.register_transformer 'text/x-ember-handlebars', 'application/javascript', self
        end

        def instance
          @instance ||= new(config)
        end

        def call(input)
          instance.call(input)
        end

        def handlebars_available?
          Barber::Precompiler.handlebars_available?
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

        template_name = actual_name(input)

        module_name =
          case config.output_type
          when :amd
            amd_template_target(config.amd_namespace, template_name)
          when :global
            template_path(template_name, config)
          else
            raise "Unsupported `output_type`: #{config.output_type}"
          end

        meta = {moduleName: module_name}

        if config.precompile
          if raw
            template = precompile_handlebars(template, input)
          else
            template = precompile_ember_handlebars(template, config.ember_template, input, meta)
          end
        else
          if raw
            template = compile_handlebars(data)
          else
            template = compile_ember_handlebars(template, config.ember_template, meta)
          end
        end

        case config.output_type
        when :amd
          "define('#{module_name}', ['exports'], function(__exports__){ __exports__['default'] = #{template} });"
        when :global
          namespace = raw ? config.raw_template_namespace : 'Ember.TEMPLATES'
          target = global_template_target(namespace, template_name, config)

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

      def precompile_ember_handlebars(template, ember_template, input, options = nil)
        dependencies = [
          Barber::Ember::Precompiler.compiler_version,
          ember_template,
          template,
          options
        ]

        input[:cache].fetch(_cache_key + dependencies) do
          super(template, ember_template, options)
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
