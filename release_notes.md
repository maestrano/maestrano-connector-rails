## 1.2.3

### Fixes
* Fix Connec! version that was not cached scoped by tenant

## 1.2.2

### Fixes
* Fix PushToConnecWork to take an organization_id insteand of an organization object

### Features
* Add a version endpoint with the framework version

### Improvments
* Add rubocop in the framework for better code quality
* Improve framework dependancies handling and update template accordingly

## 1.2.1

### Features
* Add PushToConnecWorker that give the possibilty to do jobs sequentially for a given organization and entity

## 1.2.0
/!\ For this version to work, you'll need to add `< Maestrano::Connector::Rails::EntityBase` to your `entity.rb` class

### Features
* Custom synchronization process for first sync. (For this feature to work, you'll need to implement handling of additionnal options in your `get_external_entities` method. The connector will still work as before if you don't).
* Administrations endpoints to get the synchronizations status, start a synchronization, toggle `sync_enabled` and get the connector dependancies (depenancies are declared in ConnecHelper. You'll need to overload the dependancies method if you have specific dependancies)

### Improvments
* Entity and ComplexEntity now inherits from EntityBase

## 1.1.2
/!\ This version need a migration (`bundle exec rake railties:install:migrations; bundle exec rake db:migrate`). It also requires the running of a manual script to encrypt existing oauth_keys
You'll also need to change some methods as the framework is not sending the `last_synchronization` anymore but directly the `last_synchronization_date` (`get_external_entities`, `before_sync`, `after_sync`)

### Features
* Encryption of oauth keys (you'll need to add `gem 'attr_encrypted', '~> 1.4.0'` to your Gemfile)
* No historical data option: only data created after the link to the connector will be sync. For this option to be available, you'll need to implement a `creation_date_from_external_entity_hash` method. It also requires a front end update (view, controller, js)

### Fixes
* Fix synchronization cleaning
* Minor fixes

## 1.0.4

### Fixes
* Fix uneeded creation of idmap for Connec! entities following a failure
* Fix Connec! pagination

## 1.0.3

### Fixes
* Fix an issue with options that were involuntarily shared across entities

## 1.0.2

### Fixes
* Fix an issue with integer ids

## 1.0.1

### Fixes
* Fix an issue with singleton entities

## 1.0.0

### Features
* Reference in mapping greatly simplified. See the documentation for an explanation and example: [here](https://maestrano.atlassian.net/wiki/display/DEV/Mapping+and+synchronization#Mappingandsynchronization-References).
* Smart merging available. You can specifiy field on which Connec! will attempt to merge the record with an existing one. See the framework [documentation](https://maestrano.atlassian.net/wiki/display/DEV/Examples#Examples-Smartmerging) for an example, as well as the Connec! [documentation](http://maestrano.github.io/connec/#api-|-save-data-resource-creation-post)

### Breaking changes
A major refactoring as lead to some breaking changes:
* `Entity` and `ComplexEntity` `initialize` method now take 3-4 argument instead of 0: `organization`, `connec_client`, `external_client` and `opts`
* All the **instance** methods of those classes that previously took one of these arguments have been change to not include them anymore. Full list:

**ComplexEntity & Entity:**
**`connec_model_to_external_model`**
**`external_model_to_connec_model`**
`get_connec_entities`
**`get_external_entities`**
`consolidate_and_map_data`
`push_entities_to_connec`
`push_entities_to_external`
**`before_sync`**
**`after_sync`**
**`filter_connec_entities`**


**Entity:**
**`map_to_external`**
**`map_to_connec`**
`push_entities_to_connec_to`
`batch_op`
`push_entities_to_external_to`
`push_entity_to_external`
**`create_external_entity`**
**`update_external_entity`**
`consolidate_and_map_singleton`
`map_external_entity_with_idmap`

**SubEntityBase:**
**`map_to`**

* The class method `entities_list` has been moved from `Entity` to `External`
* The `references` method has been changed with the new reference system. The framework now expect it to be an array os strings instead of an array of hashes. Furthermore, it now supports reference fields embedded in hashes and arrays.
* The following method from `Entity` as been changed from class methods to instance methods (and their arguments have been changed):
`not_modified_since_last_push_to_connec?`
`is_external_more_recent?`
`solve_conflict`
* Organization.uid is now enforced as an uniq attributes

* The following methods have been removed
`map_to_external_with_idmap`
`create_idmap_from_external_entity`
`create_idmap_from_connec_entity`
`can_update_connec?`
`id_from_ref`


- - - -
- - - -

## 0.4.4

### Features
* Add filter_connec_entities method to allow filtering in webhook workflow

### Fixes
* Truncate idmap message to avoid database errors

## 0.4.3

### Fixes
* Add `forced` option in home_controller when requesting a manual synchronization.


## 0.4.2
/!\ This release contains a new migration that you'll need to fetch and run

### Features
* Add call to before and after_sync methods during synchronization workflows
* Add logic for record flagged as inactive in the external application

### Fixes
* Fix recovery mode: recovery mode was previously on as soon as the organization had three failed synchronizations, even if a synchronization had succeed afterward. Moreover, recovery mode doesn't prevent manual synchronization anymore.
* Fix a typo in saml controller that prevented deletion of a session param.