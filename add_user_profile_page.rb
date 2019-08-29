run 'rails g migration AddExtraFieldsToUser phone_number:string description:text'
run 'rails db:migrate'


inject_into_file 'config/routes.rb', before: 'end' do
<<-RUBY
resources :users, only [:show]
RUBY

file 'app/controllers/users_controller.rb', <<-RUBY
class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end
end
RUBY


file 'app/views/users/show.slim', <<-SLIM
.row
  .col-md-3
    
  .col-md-9
SLIM