## Development Setup

 ### Setup the project
 ```
git clone <github url of the repo>

bin/setup
```
Update the configuration in `config/application.yml`.

 ### How to setup external app and get keys
 TODO: Please add a small description on how to create an account in the 3rd party app and create keys.
 Things you may want to cover:
 - How to create an account on 3rd party app.
 - How to create security credentials, like oauth client-id and client-secret.
 - Where to populate the keys/credentials in the app, this will probably be application-sample.yml.
 - Create variables in application-sample.yml to hold the keys and the URL of the 3rd party app. 

 ### Start the server
 ```
foreman start
```

 ### Run the test suite

 ```
bin/rake
```
