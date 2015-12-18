<p align="center">
  <img src="https://raw.github.com/maestrano/maestrano-connector-rails/master/maestrano.png" alt="Maestrano Logo">
  <br/>
  <br/>
</p>

Setup
#####

```console
rails new
```

```ruby
gem 'maestrano-connector-gem', git: 'https://github.com/berardpi/maestrano-connector-rails.git'
```

```console
bundle install
bundle exec figaro install
rake railties:install:migrations
rails g delayed_job:active_record
rake db:migrate
rails g connector:install
```

Getting started
###############

- Maestrano initializer (manually for now)
- application.yml API key
- oauth_controller
- external.rb
- entity.rb
- entities/
- Home and admin controllers and views

If needed: complex entities
```console
rails g connector:complex_entity
```


<!-- Maestrano Connector Engine to implements data syncrhonization between an external application API and Connec!.

Maestrano Cloud Integration is currently in closed beta. Want to know more? Send us an email to <contact@maestrano.com>.

- - -

1.  [Getting Setup](#getting-setup)
2. [Getting Started](#getting-started)
  * [Maestrano initializer](#maestrano-initializer)
  * [Oauth controller](#oauth-controller)
  * [External.rb](#external.rb)
  * [Entity.rb](#entity.rb)
  * [Pages controllers and views](#pages-controllers-and-views)
3. [Account Webhooks](#account-webhooks)

- - -

## Getting Setup
Before integrating with us you will need an Connec API ID and Connec API Key. You'll also need to have the connector application created on Maestrano in order to realize the authentication with Maestrano.

## Getting Started
Create a new rails application
```ruby
rails new .
```

maestrano-rails works with Rails 4 onwards. You can add it to your Gemfile with:

gem 'maestrano-rails'
```

Run bundle to install the gem as well as its dependencies

```console
bundle
```

You can now run the generator:
```console
rails generate connector:install
```

The generator will install several files covered in the following sections

### Maestrano initializer

TODO

### Oauth controller

TODO

### External.rb

TODO

### Entity.rb

TODO

### Pages controllers and views -->