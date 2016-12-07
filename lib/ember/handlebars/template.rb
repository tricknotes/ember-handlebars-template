require 'sprockets'
require 'barber'

require 'ember/handlebars/version'
require 'ember/handlebars/config'

module Ember
  module Handlebars
    class Template
      class << self
        def configure
          yield config
        end

        def config
          @config ||= Config.new
        end

        def setup(env)
          env.register_mime_type 'text/x-handlebars', extensions: with_js_extension(%w(.raw.hbs .raw.hjs .raw.handlebars))
          env.register_transformer 'text/x-handlebars', 'application/javascript', self

          env.register_mime_type 'text/x-ember-mustache', extensions: with_js_extension(%w(.mustache.hbs .mustache.hjs .mustache.handlebars))
          env.register_transformer 'text/x-ember-mustache', 'application/javascript', self

          env.register_mime_type 'text/x-ember-handlebars', extensions: with_js_extension(%w(.hbs .hjs .handlebars))
          env.register_transformer 'text/x-ember-handlebars', 'application/javascript', self
        end

        def setup_ember_template_compiler(path)
          Barber::Ember::Precompiler.ember_template_compiler_path = path
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

        private

        def with_js_extension(extensions)
          extensions + extensions.map {|ext| ".js#{ext}" }
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

        template_name = input[:name]

        module_name =
          case config.output_type
          when :amd
            amd_template_target(config.amd_namespace, template_name)
          when :global
            template_path(template_name, config)
          else
            raise "Unsupported `output_type`: #{config.output_type}"
          end

        meta = meta_supported? ? {moduleName: module_name} : false

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

      def handlebars?(filename)
        filename.to_s =~ /\.raw\.(handlebars|hjs|hbs)/
      end

      def mustache_to_handlebars(filename, template)
        if filename =~ /\.mustache\.(handlebars|hjs|hbs)/
          template.gsub(/\{\{(\w[^\}]+)\}\}/){ |x| "{{unbound #{$1}}}" }
        else
          template
        end
      end

      def amd_template_target(namespace, module_name)
        [namespace, module_name].compact.join('/')
      end

      def global_template_target(namespace, module_name, config)
        "#{namespace}[#{template_path(module_name, config).inspect}]"
      end

      def template_path(path, config)
        root = config.templates_root

        unless root.empty?
          Array(root).each.each do |r|
            path = path.sub(/#{Regexp.quote(r)}\//, '')
          end
        end

        path.split('/').join(config.templates_path_separator)
      end

      def precompile_handlebars(template, input)
        dependencies = [
          Barber::Precompiler.compiler_version,
          template,
        ]

        input[:cache].fetch(_cache_key + dependencies) do
          "Handlebars.template(#{Barber::Precompiler.compile(template)});"
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
          "Ember.#{ember_template}.template(#{Barber::Ember::Precompiler.compile(template, options)});"
        end
      end

      def compile_handlebars(string)
        "Handlebars.compile(#{indent(string).inspect});"
      end

      def compile_ember_handlebars(string, ember_template, options = nil)
        "Ember.#{ember_template}.compile(#{indent(string).inspect}, #{options.to_json});"
      end

      def indent(string)
        string.gsub(/$(.)/m, "\\1  ").strip
      end

      def _cache_key
        [
          self.class.name,
          VERSION,
          Barber::VERSION
        ]
      end

      def meta_supported?
        Gem::Version.new(Ember::VERSION) >= Gem::Version.new('2.7.0')
      end
    end
  end
end
