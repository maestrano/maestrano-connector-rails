## 0.4.2
/!\ This release contains a new migration that you'll need to fetch and run

### Features
* Add call to before and after_sync methods during synchronization workflows
* Add logic for record flagged as inactive in the external application

### Fixes
* Fix recovery mode: recovery mode was previously on as soon as the organization had three failed synchronizations, even if a synchronization had succeed afterward. Moreover, recovery mode doesn't prevent manual synchronization anymore.
* Fix a typo in saml controller that prevented deletion of a session param.