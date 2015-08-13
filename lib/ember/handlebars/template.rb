require 'sprockets'
require 'barber'

module Ember
  module Handlebars
    autoload :VERSION, 'ember/handlebars/version'
    autoload :Config, 'ember/handlebars/config'
    autoload :Helper, 'ember/handlebars/helper'

    case Sprockets::VERSION
    when /\A2\./, /\A3\.[12]/
      autoload :Template, 'ember/handlebars/templates/sprockets+tilt'
    when /\A3\.[03]/
      autoload :Template, 'ember/handlebars/templates/sprockets_only'
    else
      raise "Unsupported sprockets version: #{Sprockets::VERSION}"
    end
  end
end
