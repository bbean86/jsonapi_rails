require "jsonapi_rails/version"
require "jsonapi_rails/params_to_object"
require "jsonapi_rails/parser"

module JsonApiRails
  # Error is the base class for JsonApiRails. It can be rescued in a controller
  # or the individual errors can be rescued, though the namespacing is a bit
  # extensive..
  Error = Class.new(StandardError)
  ValidationError = Class.new(Error)
  UnknownAttributeError = Class.new(Error)
  UnknownRelationshipError = Class.new(Error)
  MIMETYPE = 'application/vnd.api+json'
end
