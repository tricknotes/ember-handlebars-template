require 'minitest_helper'

class TestEmberHandlebarsTemplate < Minitest::Test
  def setup
    @env = Sprockets::Environment.new
    @env.append_path File.expand_path('../fixtures', __FILE__)

    Ember::Handlebars::Template.setup @env
  end

  def test_that_it_has_a_version_number
    refute_nil ::Ember::Handlebars::VERSION
  end

  def test_should_replace_separators_with_templates_path_separator
    with_template_root('', '-') do
      asset = @env['app/templates/application.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["app-templates-application"\]}, asset.to_s
    end
  end

  def test_should_strip_only_first_occurence_of_templates_root
    with_template_root('app', '/') do
      asset = @env['app/templates/app/example.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["templates/app/example"\]}, asset.to_s
    end
  end

  def test_should_strip_templates_root_with_slash_in_it
    with_template_root('app/templates') do
      asset = @env['app/templates/app/example.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["app/example"\]}, asset.to_s
    end
  end

  def test_should_strip_different_template_roots
    with_template_root(['templates', 'templates_mobile']) do
      asset = @env['templates/hi.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["hi"\]}, asset.to_s
    end

    with_template_root(['templates', 'templates_mobile']) do
      asset = @env['templates_mobile/hi.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["hi"\]}, asset.to_s
    end
  end

  def test_should_allow_partial_templates_root_matching
    with_template_root('templates') do
      asset = @env['app/templates/hi.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["app/hi"\]}, asset.to_s
    end
  end

  def test_should_not_handle_partial_matching_template
    with_template_root('templates') do
      asset = @env['templates_mobile/hi.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["templates_mobile/hi"\]}, asset.to_s
    end
  end

  def test_should_compile_template_named_as_index
    with_template_root('templates') do
      asset = @env['templates/index.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["index"\]}, asset.to_s
    end
  end

  def test_should_compile_template_named_as_index_without_dir
    with_template_root('') do
      asset = @env['index.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["index"\]}, asset.to_s
    end
  end

  def test_template_with_AMD_output_using_app_namespace
    with_amd_output('app') do
      asset = @env['templates/hi.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{define\('app/templates/hi'}, asset.to_s
    end
  end

  def test_template_with_AMD_output_using_nil_namespace
    with_amd_output(nil) do
      asset = @env['templates/hi.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{define\('templates/hi'}, asset.to_s
    end
  end

  def test_compile_template_with_Handlebars_namespace
    with_ember_template 'Handlebars' do
      asset = @env['templates/hi.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["hi"\] = Ember\.Handlebars\.template\(}, asset.to_s
    end
  end

  def test_compile_template_with_HTMLBars_namespace
    with_ember_template 'HTMLBars' do
      asset = @env['templates/hi.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{Ember.TEMPLATES\["hi"\] = Ember\.HTMLBars\.template\(}, asset.to_s
    end
  end

  def test_should_have_module_name_with_global_output
    asset = @env['templates/hi.js']

    assert_equal 'application/javascript', asset.content_type
    assert_match %r{Ember.TEMPLATES\["hi"\]}, asset.to_s
    assert_match %r{"moduleName": "hi"}, asset.to_s
  end

  def test_should_have_module_name_with_AMD_output
    with_amd_output('app') do
      asset = @env['templates/hi.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{define\('app/templates/hi'}, asset.to_s
      assert_match %r{"moduleName": "app/templates/hi"}, asset.to_s
    end
  end

  def test_compile_raw_template
    with_ember_template 'Handlebars' do
      asset = @env['types/raw-hi.js']

      assert_equal 'application/javascript', asset.content_type
      assert_match %r{JST\["types/raw-hi"\] = Handlebars\.template\(}, asset.to_s
    end
  end

  def test_configurable_raw_template_with_namespace
    with_ember_template 'Handlebars' do
      with_raw_template_namespace 'JS_TEMP' do
        asset = @env['types/raw-hi.js']

        assert_equal 'application/javascript', asset.content_type
        assert_match %r{JS_TEMP\["types/raw-hi"\] = Handlebars\.template\(}, asset.to_s
      end
    end
  end

  def test_compile_template_with_hjs_extname
    asset = @env['extname/hjs.js']

    assert_equal 'application/javascript', asset.content_type
    assert_match %r{Ember.TEMPLATES\["extname/hjs"\]}, asset.to_s
  end

  def test_compile_template_with_handlebars_extname
    asset = @env['extname/handlebars.js']

    assert_equal 'application/javascript', asset.content_type
    assert_match %r{Ember.TEMPLATES\["extname/handlebars"\]}, asset.to_s
  end

  def test_should_respond_with_handlebars_detection
    assert_equal Ember::Handlebars::Template.handlebars_available?,
                 true,
                 'Handlebars should be available since it is a development dependency.'
  end

  private

  def config
    Ember::Handlebars::Template.config
  end

  def with_template_root(root, sep=nil)
    old, config.templates_root = config.templates_root, root

    if sep
      old_sep, config.templates_path_separator = config.templates_path_separator, sep
    end

    yield
  ensure
    config.templates_root = old
    config.templates_path_separator = old_sep if sep
  end

  def with_amd_output(namespace)
    old, config.output_type = config.output_type, :amd
    old_namespace, config.amd_namespace = config.amd_namespace, namespace

    yield
  ensure
    config.output_type = old
    config.amd_namespace = old_namespace
  end

  def with_ember_template(template)
    old, config.ember_template = config.ember_template, template

    yield
  ensure
    config.ember_template = old
  end

  def with_raw_template_namespace(ns)
    old, config.raw_template_namespace = config.raw_template_namespace, ns

    yield
  ensure
    config.raw_template_namespace = old
  end
end
