# Rails Templates

Quickly generate a rails app with custom configuration
using [Rails Templates](http://guides.rubyonrails.org/rails_application_templates.html).


## Minimal

Get a minimal rails 6.0 app ready to be deployed on Heroku with Bootstrap, Simple form and debugging gems.

```bash
rails new \
  --database postgresql \
  -m https://raw.githubusercontent.com/Kaolla/rails-templates/master/minimal.rb \
  APP_NAME
```

## Devise

Same as minimal **plus** a Devise install with a generated `User` model.

```bash
rails new \
  --database postgresql \
  -m https://raw.githubusercontent.com/Kaolla/rails-templates/master/devise.rb \
  APP_NAME
```
