<p align="center">
  <img src="https://raw.github.com/berardpi/maestrano-connector-rails/master/maestrano.png" alt="Maestrano Logo">
  <br/>
  <br/>
</p>

Maestrano Connector Engine to implements data syncrhonization between an external application API and Connec!.

Maestrano Connector Integration is currently in closed beta. Want to know more? Send us an email to <contact@maestrano.com>.

- - -

1. [Getting Setup](#getting-setup)
2. [Getting Started](#getting-started)
  * [Integration with Maestrano](#integration-with-maestrano)
  * [Integration with the external application](#integration-with-the-external-application)
3. [Preparing synchronizations](#preparing-synchronizations)
  * [External.rb](#external.rb)
  * [Entity.rb](#entity.rb)
  * [Mapping entities](#mapping-entities)
4. [Pages controllers and views](#pages-controllers-and-views)
5. [Complex entities](#complex-entities)

- - -

## Getting Setup
Before integrating with us you will need an Connec!™ API ID and Connec!™ API Key. You'll also need to have the connector application created on Maestrano in order to realize the authentication with Maestrano.

## Getting Started
Create a new rails application using the connector template
```console
rails new <project_name> -m https://raw.githubusercontent.com/Berardpi/maestrano-connector-rails/master/template/maestrano-connector-template.rb
```

If and only if you have an error in the template's rails generate step, you'll need to re-run the following command in your project folder:
```console
bundle
rails g connector:install
rails g delayed_job:active_record
rake db:migrate
```

### Integration with Maestrano

First thing to do is to put your Connec!™ API keys in the config/application.yml:
```ruby
connec_api_id: 'API_ID'
connec_api_key: 'API_KEY'
```

The only other thing you need to do is to set your configuration in config/initializers/maestrano.rb. The one line you need to look for and change is:
```ruby
config.app.host = 'http://path_to_app'
```
The rest of the config has default values, so you can take a look but you don't really need to change anything else.

Please note that the connectors support multi-tenancy, so you may have to set up configuration for tenant other than Maestrano (the default one).

Those configuration are automatically retrieve by Maestrano via a metadata endpoint that is provided by the gem, so you're all setup as it is.

Time to test! If your launch your application (please make sure that you launch the application on the same path as the one in the config file). If you click on the 'Link your Maestrano account' link on your connector home page, you should be able to do a full sso process with Maestrano.

### Integration with the external application

Now that you're all setup with Maestrano, it's time to take a look at the external application you are integrating with. Hopefully it has one or several gems for both the authentication process and the API calls. In any case, you'll need to take a look at their documentation.

You will probably have to request API keys and adds them to the application.yml alongside the Maestrano's ones.

The connector engine is thought to be able to use oauth authentication processes, and an oauth_controller is provided as an example. Please note that it is only an example and you will have to implements most of it, and to create the needed routes, and use them in the provided view.

If all went well, you should now be able to use the 'Link this company to...' link on the home page. Congrats!

## Preparing synchronizations

The aim of the connector is to perform synchronizations between Connec!™ and the external application, meaning fetching data on both ends, process them, and push the result to the relevant end. The Connec!™ part and the synchronization process itself is handle by the engine, so all you have to do is to implements some methods to work with the external application.

### External.rb

First file to look for is the external.rb class (in models/maestrano/connector/rails/). It contains two methods that you need to implements:

* external_name, which is used fr logging purpose only, and should only return the name of the external application, e.g.
```ruby
def self.external_name
  'This awesome CRM'
end
```
* get_client, which should return either the external application gem api client, or, in the worst case, a custom HTTParty client.


### Entity.rb

The second important file is the entity.rb class (in the same folder). It contains a method to declare the entity synchronizable by your connector (more on that later), some methods to get and push data to the external application api, and lastly two methods to extract id and update date from the entity format sent by the external application.

The details of each methods are explained in the entity.rb file provided.

### Mapping entities

Now that you're all setup with both Connec!™ and the external application, it's time to decide which entities (contacts, accounts, events, ...) you want to synchronize. For each type of entity your connector will synchronize, you will need to create a class that inherits from Maestrano::Connector::Rails::Entity.

An example of such a class in provided in the models/entities/ folder, and demonstrates which methods you'll need to implements for each entity. The main thing to do is the mapping between the external entity and the Connec!™ entity. For the mapping, we use the hash_mapper gem (<https://github.com/ismasan/hash_mapper>).

This type of entity class enable 1 to 1 model correspondance. For more complex needs, please refer to the complex entity section below.

You'll find the connec API documentation here: <http://maestrano.github.io/connec/>, and should also refer to the external application API documentation.

Also don"t forget that each entity your connector synchronize should be declare in the entity.rb class, and, because the synchronizable entities are stored in th db for each organization, you'll need to create a migration for exisiting organization if you add an entity.

#### Overriding methods

To fit each entity specific need, you can overide all methods define in the entity class, including those implemented by the engine.

In particular, you will probably need to override the mapping methods to realize reference between entities (this can't be done during the mapping because it requires the organization id).

For example:
```ruby
def map_to_connec(entity, organization)
  if id = entity['AccountId']
    idmap = Maestrano::Connector::Rails::IdMap.find_by(external_entity: 'account', external_id: id, organization_id: organization.id, connec_entity: 'organization')
    entity['AccountId'] = idmap ? idmap.connec_id : ''
  end
  self.mapper_class.denormalize(entity)
end
```

## Pages controllers and views

The home and admin pages views and controllers are provided as example, but you are free to customize them and the styling is left for you to do.

## Complex entities

For more complex correspondances, like 1 to many or many to many ones, you can use the complex entity workflow. To see how it works, you can run
```console
rails g connector:complex_entity
```

This will generate some example files demonstrating a 1 to 2 correspondance between Connec!™ person and external contact and lead data models.

The complex entities workflow uses two methods to pre-process data which you have to implements for each complex entity (see contact_and_lead.rb). They are called before the mapping step, and you can use them to perform any data model specific operations.