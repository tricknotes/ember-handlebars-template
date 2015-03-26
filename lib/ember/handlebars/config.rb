module Ember
  module Handlebars
    class Config
      OPTIONS = [
        :precompile,
        :ember_template,
        :output_type,
        :amd_namespace,
        :templates_root,
        :templates_path_separator
      ].freeze

      attr_accessor *OPTIONS

      def initialize
        self.precompile = true
        self.ember_template = 'HTMLBars'
        self.output_type = :global
        self.amd_namespace = nil
        self.templates_root = 'templates'
        self.templates_path_separator = '/'
      end

      def to_hash
        Hash[OPTIONS.map {|option| [option, __send__(option)] }]
      end
    end
  end
end
