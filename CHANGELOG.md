v 0.4.1-beta
Adds support for nested includes

v 0.4.0-beta
Renames the `whitelisted` option to `permitted`

v 0.3.2-beta
Adds the `whitelisted` option to `#parse_json_api_params`

v 0.3.1-beta
Version bump for json api ruby dependency. Fixes duplication in the
`included` field for collection resources.

v 0.3.0-beta
Removes links from serialized responses, the feature is still in beta

v 0.2.1-beta
Promotes `json_api_ruby` from dev dependencies to dependencies

v 0.2.0-beta
Fixes #11. Relationships must now be defined on the model and Resource to be
assigned. To-many relationships can now be set to `null` without error.

v 0.1.1-beta
Fixes an issue with comparing strings to symbols when building the list of
assignable attributes.

v 0.1.0-beta
Fixes #8. Attributes must be defined on the model or Resource to be assigned.
Updates #parse_json_api_params interface to be more readable.

v 0.0.2-beta
Fix issue with `ParamsToObject` relationship parsing

v 0.0.1-beta
Initial release, includes `json_api` and `json_api_errors` renderers and
helpers for use in Rails controllers.
