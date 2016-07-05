# Setup
```
rvm install ruby-2.3.1
gem install bundler
bundle install
```

# Test commands
```
bundle exec rake app:db:test:prepare
bundle exec rspec
bundle exec rubocop
```