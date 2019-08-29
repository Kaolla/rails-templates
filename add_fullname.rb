run 'rails g migration AddFullnameToUser fullname:string'

inject_into_file 'app/models/user.rb', before: 'end' do
<<-RUBY
validates :fullname, presence: true, length: { maximum: 50 }
RUBY

inject_into_file 'app/controllers/application_controller.rb', before: 'end' do
<<-RUBY

before_action configure_permitted_parameters, if: :devise_controller?

protected

def configure_permitted_parameters
  devise_parameter_sanitizer.permit(:sign_up, keys: [:fullname])
  devise_parameter_sanitizer.permit(:account_update, keys: [:fullname])
end
RUBY