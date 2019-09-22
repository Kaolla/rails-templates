run 'pgrep spring | xargs kill -9'

def add_gems
  run 'rm Gemfile'
  file 'Gemfile', <<-RUBY
  source 'https://rubygems.org'

  ruby '#{RUBY_VERSION}'

  gem 'rails', '#{Rails.version}'
  gem 'pg', '>= 0.18', '< 2.0'
  gem 'puma', '~> 4.1'
  gem 'sass-rails', '~> 5'
  gem 'webpacker', '~> 4.0'
  gem 'turbolinks', '~> 5'
  gem 'jbuilder', '~> 2.7'

  gem 'bootsnap', '>= 1.4.2', require: false

  group :development do
    # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
    gem 'web-console', '>= 3.3.0'
    gem 'listen', '>= 3.0.5', '< 3.2'
    # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
    gem 'spring'
    gem 'spring-watcher-listen', '~> 2.0.0'
  end

  group :development, :test do
    gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
    gem 'pry-rails'
    gem 'annotate', '~> 2.7', '>= 2.7.1'
    gem 'brakeman'
    gem 'bundler-audit'
    gem 'letter_opener_web', '~> 1.3', '>= 1.3.4'
  end

  group :test do
    # Adds support for Capybara system testing and selenium driver
    gem 'capybara', '>= 2.15'
    gem 'selenium-webdriver'
    # Easy installation and use of web drivers to run system tests with browsers
    gem 'webdrivers'
  end

  gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

  # Custom adds
  gem 'attr_encrypted', '~> 3.1'
  gem 'devise', '~> 4.7'
  gem 'devise_invitable', '~> 2.0', '>= 2.0.1'
  gem 'devise_masquerade', '~> 0.6.5'
  gem 'inline_svg', '~> 1.3', '>= 1.3.1'
  gem 'local_time', '~> 2.1'
  gem 'name_of_person', '~> 1.0'
  gem 'friendly_id', '~> 5.2', '>= 5.2.5'
  gem 'pagy', '~> 3.0'
  gem 'pg_search', '~> 2.3'
  gem 'turbolinks_render', '~> 0.9.12'
  gem 'sidekiq', '~> 5.2', '>= 5.2.5'
  gem 'cloudinary', require: false

  gem 'redis', '~> 4.0'

  # We always want the latest versions of these gems, so no version numbers
  gem 'omniauth'
  gem 'strong_migrations'
  gem 'whenever', require: false

  gem 'slim'
  gem 'autoprefixer-rails'
  gem 'uglifier'
  gem 'simple_form'
  gem 'font-awesome-sass', '~> 5.6.1'
  gem 'slim'
  RUBY
end

# Ruby version
########################################
file '.ruby-version', RUBY_VERSION

def add_configs 
    file 'Procfile', <<-YAML
  web: rails server
  worker: sidekiq
  YAML

    file 'Procfile.dev', <<-TXT
  web: bundle exec rails server
  worker: bundle exec sidekiq
  webpack: bundle exec bin/webpack-dev-server
  TXT

    file '.foreman', <<-TXT
  procfile: Procfile.dev
  TXT
end

def add_assets
  # run 'rm -rf app/assets/stylesheets'
  run 'rm -rf vendor'
  # run 'curl -L https://github.com/Kaolla/rails-stylesheets/archive/master.zip > stylesheets.zip'
  run 'curl -L https://github.com/Kaolla/rails-tailwind-components/archive/master.zip > components.zip'
  run 'unzip components.zip -d app/assets && rm components.zip && mv app/assets/rails-tailwind-components-master app/assets/components'
end



# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

def add_layout
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
      = javascript_pack_tag 'application', 'data-turbolinks-track': 'reload'

      = render 'shared/navbar'
      = render 'shared/flashes'
      = yield
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
end

def add_readme
  markdown_file_content = <<-MARKDOWN
  Rails app created by Romain Manguin.
  MARKDOWN
  file 'README.md', markdown_file_content, force: true
end

def set_generators
  generators = <<-RUBY
  config.generators do |generate|
        generate.assets false
        generate.helper false
        generate.test_framework  :test_unit, fixture: false
      end
  RUBY

  environment generators
end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  insert_into_file "config/routes.rb",
    "require 'sidekiq/web'\n\n",
    before: "Rails.application.routes.draw do"

  insert_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
<<-RUBY
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
RUBY
  end
end

def add_announcements
  generate "model Announcement published_at:datetime announcement_type name description:text"
  route "resources :announcements, only: [:index]"
end

def add_notifications
  generate "model Notification recipient_id:bigint actor_id:bigint read_at:datetime action:string notifiable_id:bigint notifiable_type:string"
  route "resources :notifications, only: [:index]"
end

def add_whenever
  run "wheneverize ."
end

def add_friendly_id
  generate "friendly_id"

  insert_into_file(
    Dir["db/migrate/**/*friendly_id_slugs.rb"].first,
    "[5.2]",
    after: "ActiveRecord::Migration"
  )
end

def add_user
  generate('devise:install')
  generate :devise, "User",
           "first_name",
           "last_name",
           "announcements_last_read_at:datetime",
           "admin:boolean"

  # Set admin default to false
  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end

  # Add Devise masqueradable to users
  inject_into_file("app/models/user.rb", "omniauthable, :masqueradable, :", after: "devise :")
end

def set_devise_secret
  gsub_file "config/initializers/devise.rb",
    /  # config.secret_key = .+/,
    "  config.secret_key = Rails.application.credentials.secret_key_base"
end

def add_tailwind
  run 'mkdir app/javascript/css'
  run "yarn tailwind init app/javascript/stylesheets/tailwind.js"


  run "touch app/javascript/stylesheets/application.scss"

  file 'app/javascript/stylesheets/src/application.scss', <<-TXT
  @import "tailwindcss/base";
  @import "tailwindcss/components";

  @import 'components/base';
  @import 'components/announcements';
  @import 'components/alert';
  @import 'components/avatars';
  @import 'components/typography';
  @import 'components/buttons';
  @import 'components/icons';
  @import 'components/forms';
  @import 'components/util';
  @import 'components/nav';
  @import 'components/code';
  @import 'components/docs';
  @import 'components/animation';
  @import 'components/tabs';
  @import 'components/pagination';
  @import 'components/connected_accounts';
  @import 'components/actiontext';
  @import 'components/direct_uploads';
  @import 'components/trix';

  @import "tailwindcss/utilities";
  TXT
end

def add_js
  run "yarn add jquery popper.js tailwindcss stimulus local-time"

  run 'rm app/javascript/packs/application.js'

  file 'app/javascript/packs/application.js', <<-JS
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")
require("trix")
require("@rails/actiontext")

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import "stylesheets/application"
import "controllers"
JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do
<<-JS
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
end

add_gems
add_configs 
add_assets
add_layout
add_readme
set_generators
add_sidekiq
add_announcements
add_notifications
add_whenever
add_friendly_id
add_user
set_devise_secret
add_js
add_tailwind

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate(:controller, 'pages', 'home', 'terms', 'privacy', '--skip-routes', '--no-test-framework')

  # Routes
  ########################################
  route "root to: 'pages#home'"
  route "get '/terms', to: 'pages#terms'"
  route "get '/privacy', to: 'pages#privacy'"



  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<-RUBY
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :masquerade_user!
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

  def terms
  end

  def privacy
  end
end
RUBY

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Rubocop
  ########################################
  run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

  # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit'"
end
