module Ember
  module Handlebars
    class Config
      attr_accessor :precompile,
        :ember_template,
        :output_type,
        :amd_namespace,
        :raw_template_namespace,
        :templates_root,
        :templates_path_separator

      def initialize
        self.precompile = true
        self.ember_template = 'HTMLBars'
        self.output_type = :global
        self.amd_namespace = nil
        self.raw_template_namespace = 'JST'
        self.templates_root = 'templates'
        self.templates_path_separator = '/'
      end
    end
  end
end
