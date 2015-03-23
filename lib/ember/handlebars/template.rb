require 'sprockets'
require 'barber'

module Ember
  module Handlebars
    autoload :VERSION, 'ember/handlebars/version'
    autoload :Config, 'ember/handlebars/config'

    class Template < Tilt::Template
      class << self
        def configure
          yield config
        end

        def default_mime_type
          'application/javascript'
        end

        def config
          @config ||= Config.new
        end
      end

      def prepare; end

      def evaluate(scope, locals, &block)
        raw = handlebars?(scope)

        if raw
          template = data
        else
          template = mustache_to_handlebars(scope, data)
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
          target = amd_template_target(scope)

          "define('#{target}', ['exports'], function(__exports__){ __exports__['default'] = #{template} });"
        when :global
          target = global_template_target(scope)

          "#{target} = #{template}\n"
        else
          raise "Unsupported `output_type`: #{config.output_type}"
        end
      end

      private

      def handlebars?(scope)
        scope.pathname.to_s =~ /\.raw\.(handlebars|hjs|hbs)/
      end

      def amd_template_target(scope)
        [config.amd_namespace, scope.logical_path.split(".").first].compact.join('/')
      end

      def global_template_target(scope)
        "Ember.TEMPLATES[#{template_path(scope.logical_path).inspect}]"
      end

      def compile_handlebars(string)
        "Handlebars.compile(#{indent(string).inspect});"
      end

      def precompile_handlebars(string)
        "Handlebars.template(#{Barber::Precompiler.compile(string)});"
      end

      def compile_ember_handlebars(string, ember_template = 'Handlebars')
        "Ember.#{ember_template}.compile(#{indent(string).inspect});"
      end

      def precompile_ember_handlebars(string, ember_template = 'Handlebars')
        "Ember.#{ember_template}.template(#{Barber::Ember::Precompiler.compile(string)});"
      end

      def mustache_to_handlebars(scope, template)
        if scope.pathname.to_s =~ /\.mustache\.(handlebars|hjs|hbs)/
          template.gsub(/\{\{(\w[^\}]+)\}\}/){ |x| "{{unbound #{$1}}}" }
        else
          template
        end
      end

      def template_path(path)
        root = config.templates_root

        if root.kind_of? Array
          root.each do |root|
            path.sub!(/#{Regexp.quote(root)}\//, '')
          end
        else
          unless root.empty?
            path.sub!(/#{Regexp.quote(root)}\/?/, '')
          end
        end

        path = path.split('/')

        path.join(config.templates_path_separator)
      end

      def config
        self.class.config
      end

      def indent(string)
        string.gsub(/$(.)/m, "\\1  ").strip
      end
    end
  end
end
