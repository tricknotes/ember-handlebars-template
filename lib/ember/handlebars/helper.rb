module Ember
  module Handlebars
    module Helper
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def setup_ember_template_compiler(path)
          Barber::Ember::Precompiler.ember_template_compiler_path = path
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

      def global_template_target(module_name, config)
        "Ember.TEMPLATES[#{template_path(module_name, config).inspect}]"
      end

      def template_path(path, config)
        root = config.templates_root

        unless root.empty?
          Array(root).each.each do |r|
            path.sub!(/#{Regexp.quote(r)}\//, '')
          end
        end

        path = path.split('/')

        path.join(config.templates_path_separator)
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

      def indent(string)
        string.gsub(/$(.)/m, "\\1  ").strip
      end
    end
  end
end
