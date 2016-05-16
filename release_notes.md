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

* Idmap field `connec_id` is depreceated and not filled or used anymore by the framework
* The class method `entities_list` has been moved from `Entity` to `External`
* The `references` method has been changed with the new reference system. The framework now expect it to be an array os strings instead of an array of hashes. Furthermore, it now supports reference fields embedded in hashes and arrays.
* The following method from `Entity` as been changed from class methods to instance methods (and their arguments have been changed):
`not_modified_since_last_push_to_connec?`
`is_external_more_recent?`
`solve_conflict`

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