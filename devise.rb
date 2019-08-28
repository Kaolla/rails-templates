run 'pgrep spring | xargs kill -9'

# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'

ruby '#{RUBY_VERSION}'

gem 'rails', '#{Rails.version}'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5'
gem 'webpacker', '~> 4.0'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.7'

#{"gem 'bootsnap', '>= 1.4.2', require: false" if Rails.version >= "5.2"}

group :development do
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Custom adds
gem 'redis'
gem 'autoprefixer-rails'
gem 'uglifier'
gem 'sassc-rails'
gem 'simple_form'
gem 'font-awesome-sass', '~> 5.6.1'
gem 'devise', '~> 4.7.0'
gem 'slim'
RUBY

# Ruby version
########################################
file '.ruby-version', RUBY_VERSION

# Procfile
########################################
file 'Procfile', <<-YAML
web: bundle exec puma -C config/puma.rb
YAML

# Assets
########################################
run 'rm -rf app/assets/stylesheets'
run 'rm -rf vendor'
run 'curl -L https://github.com/Kaolla/rails-stylesheets/archive/master.zip > stylesheets.zip'
run 'unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets'

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Layout
########################################
run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.slim', <<-SLIM
doctype html
html
  head
    meta content=("text/html; charset=UTF-8") http-equiv="Content-Type" /
    meta charset="UTF-8" /
    meta content="width=device-width, initial-scale=1, shrink-to-fit=no" name="viewport" /
    title TODO
    = csrf_meta_tags
    = action_cable_meta_tag
    = csp_meta_tag

    = stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload'
    = stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload'
    / Uncomment to import CSS in app/javascript/packs/application.js

    = render 'shared/navbar'
    = render 'shared/flashes'
    = yield
    = javascript_include_tag 'application'
    = javascript_pack_tag 'application', 'data-turbolinks-track': 'reload'
SLIM

file 'app/views/shared/_flashes.slim', <<-SLIM
- if notice
  .alert.alert-info.alert-dismissible.fade.show.m-1 role="alert" 
    = notice
    button.close aria-label="Close" data-dismiss="alert" type="button" 
      span aria-hidden="true"  ×
- if alert
  .alert.alert-warning.alert-dismissible.fade.show.m-1 role="alert" 
    = alert
    button.close aria-label="Close" data-dismiss="alert" type="button" 
      span aria-hidden="true"  ×
SLIM

run 'curl -L https://raw.githubusercontent.com/Kaolla/awesome-navbars/master/templates/_navbar_wagon.slim > app/views/shared/_navbar.slim'
run 'curl -L https://raw.githubusercontent.com/Kaolla/rails-templates/master/logo.png > app/assets/images/logo.png'

# README
########################################
markdown_file_content = <<-MARKDOWN
Rails app generated with custom template, created by Romain Manguin.
MARKDOWN
file 'README.md', markdown_file_content, force: true

# Generators
########################################
generators = <<-RUBY
config.generators do |generate|
      generate.assets false
      generate.helper false
      generate.test_framework  :test_unit, fixture: false
    end
RUBY

environment generators

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate('simple_form:install', '--bootstrap')
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')

  # Routes
  ########################################
  route "root to: 'pages#home'"

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<-RUBY
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
end
RUBY

  # migrate + devise views
  ########################################
  rails_command 'db:migrate'
  generate('devise:views')

  # Pages Controller
  ########################################
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<-RUBY
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end
end
RUBY

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Webpacker / Yarn
  ########################################
  run 'mkdir app/javascript/packs/src'
  file 'app/javascript/packs/src/application.scss', <<-TXT
    @import '~bootstrap/scss/bootstrap';
  TXT
  run 'yarn add popper.js jquery bootstrap'
  run 'rm app/javascript/packs/application.js'

  file 'app/javascript/packs/application.js', <<-JS
import "bootstrap";
import "./src/application.scss";
JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do
<<-JS
const { environment } = require('@rails/webpacker')

const webpack = require('webpack')
// Preventing Babel from transpiling NodeModules packages
environment.loaders.delete('nodeModules');
// Bootstrap 4 has a dependency over jQuery & Popper.js:
environment.plugins.prepend('Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    Popper: ['popper.js', 'default']
  })
)
JS
  end

  # Rubocop
  ########################################
  # run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

  # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit with custom devise template'"
end
