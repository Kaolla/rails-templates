# WIP

run 'rails active_storage:install'

run 'rails db:migrate'

inject_into_file 'app/models/user.rb', before: 'devise :database_authenticatable, :registerable,' do
<<-RUBY
has_one_attached :avatar

RUBY


inject_into_file 'app/helpers/application_helper.rb', after: 'module ApplicationHelper' do
<<-RUBY
def avatar_url(user)
  if user.avatar.attached?
    url_for(user.avatar)
  elsif user.image?
    user.image
  else
    ActionController::Base.helpers.asset_path('icon_default_avatar.png')
  end
end
RUBY