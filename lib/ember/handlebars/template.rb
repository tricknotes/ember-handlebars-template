require 'sprockets'
require 'barber'

module Ember
  module Handlebars
    autoload :VERSION, 'ember/handlebars/version'
    autoload :Config, 'ember/handlebars/config'
    autoload :Helper, 'ember/handlebars/helper'

    case Sprockets::VERSION
    when /\A2\./
      autoload :Template, 'ember/handlebars/templates/sprockets2'
    when /\A3\./
      autoload :Template, 'ember/handlebars/templates/sprockets3'
    else
      raise "Unsupported sprockets version: #{Sprockets::VERSION}"
    end
  end
end
