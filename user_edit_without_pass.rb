file 'app/controllers/registrations_controller.rb', <<-RUBY
class RegistrationsController < Devise::RegistrationsController
    protected
    def update_resource(resource, params)
        resource.update_without_password(params)
    end
end
RUBY

inject_into_file 'config.routes.rb', after: 'devise_for :users' do
<<-RUBY
devise_for :users, 
              path: '', 
              controllers: {registrations: 'registrations'}
RUBY