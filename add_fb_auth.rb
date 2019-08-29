inject_into_file 'Gemfile', <<-RUBY
gem 'omniauth', '~> 1.9.0'
gem 'omniauth-facebook', '~> 5.0.0'
RUBY

run 'bundle'

run 'rails g migration AddFacebookColumnsToUser provider uid image'
run 'rails db:migrate'

inject_into_file 'config/initializers/devise.rb', before: 'end' do
<<-RUBY

config.omniauth :facebook,
                "#{ENV['FACEBOOK_APP_ID']}",
                "#{ENV['FACEBOOK_SECRET_ID']}",
                scope: 'email',
                info_fields: 'email,name',
                image_size: 'large'
RUBY

inject_into_file 'app/models/user.rb', after: ':validatable, ' do
<<-RUBY
:omniauthable
RUBY

inject_into_file 'app/models/user.rb', after: 'end' do
<<-RUBY
def self.from_omniauth(auth)
  user = User.where(email: auth.info.email).first

  if user
    if !user.provider
      user.update(uid: auth.uid, provider: auth.provider, image: auth.info.image)
    end
    user
  else
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.full_name = auth.info.name   # assuming the user model has a name
      user.image = auth.info.image # assuming the user model has an image

      user.uid = auth.uid
      user.provider = auth.provider
    end
  end
end
RUBY

file 'app/controllers/omniauth_callbacks_controller.rb', <<-RUBY
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: "Facebook") if is_navigational_format?
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end
RUBY

inject_into_file 'app/views/devise/sessions/new.slim', after: '= f.button :submit, "Log in", class: "btn-primary w-100"' do
<<-SLIM
= link_to "Sign in with Facebook", user_facebook_omniauth_authorize_path, class: "btn btn-primary"
SLIM
inject_into_file 'app/views/devise/registrations/new.slim', after: '= f.button :submit, "Log in", class: "btn-primary w-100"' do
<<-SLIM
= link_to "Sign in with Facebook", user_facebook_omniauth_authorize_path, class: "btn btn-primary"
SLIM