module JsonApiRails
  # {ParamsToObject} converts a JSONAPI compliant hash-like object into a
  # ready-to-use model.
  class ParamsToObject
    attr_reader :object
    attr_reader :attributes
    # Array of attribute names not set on the Resource but that should be allowed
    # Useful for transient attributes, such as a credit card number
    attr_reader :permitted

    def initialize(data_hash, ar_relation = nil, resource_class = nil, permitted = [])
      validate_json(data_hash)

      data = data_hash[:data]
      @object = setup_object(data, ar_relation)
      @resource_class = resource_class
      @permitted = permitted

      @attributes = Hash(data[:attributes])
      @relationships = Hash(data[:relationships])

      assign_attributes
      assign_relationships
    end

    # Finds or initializes (if given a uuid) the object specified by the type
    # and, if present, the id from the data hash
    #
    # @param [Hash] data The data element of the JSON API hash
    # @param [ActiveRecord::Relation] ar_relation An ActiveRecord::Relation
    # object, used to build new objects from. This allows a controller to
    # properly scope found/initialized objects.
    # @option data [String] :id The ID of the object we should be searching
    # for. This can be either a database id or a UUID. If given a UUID, will
    # initialize a new object if it does not exist.
    # @option data [String] :type The type of object (person, article, etc)
    #
    # @return [klass] An instance of the object specified by *klass*
    def setup_object(data, ar_relation)
      type = data[:type]
      klass = ar_relation || type.classify.constantize

      return klass.new if data[:id].blank?

      # such hack
      # assume it's a UUID and *klass* responds to find_or_initialize_by_uuid
      if data[:id].index('-') != nil
        if klass.respond_to? :find_or_initialize_by_uuid
          # handle Rails 3 ActiveRecord classes
          klass.find_or_initialize_by_uuid(data[:id])
        else
          # handle Rails 4 ActiveRecord classes
          klass.find_or_initialize_by(uuid: data[:id])
        end
      else
        klass.find_by_id(data[:id])
      end
    end

    # Check that we receive a hash that contains a *data* object and that the
    # *data* object contains a *type* field
    #
    # @param [Hash] json_data The JSON data to be validated.
    #   Should have a structure similar to the following:
    #     {
    #       data: {
    #         type: 'people'
    #       }
    #     }
    def validate_json(json_data)
      validation_hash = {
        data: { type: 'string' }
      }

      validator = HashValidator.validate(json_data, validation_hash)
      check_validation_errors(validator)
    end

    # Calls *save* on the underlying object
    def save
      object.save
    end

    # Calls *save!* on the underlying object. This will raise an error if the save fails
    def save!
      object.save!
    end

    # Calls the setter method "attr=" with the attribute value for each
    # attribute passed into this class on initialization
    #
    # @raise [UnknownAttributeError] raised if the `resource` does not define
    #   the attribute
    def assign_attributes
      attributes.each_with_object({}) do |(attr, value), hsh|
        unless permitted?(attr)
          message = "`#{resource.class}' does not have attribute " \
                    "`#{attr.to_s.gsub('=', '')}'"
          fail UnknownAttributeError.new(message)
        end
        hsh[attr] = value if assignable_attribute_names.include? attr.to_s
      end.each do |attr,value|
        check_method("#{attr}=")
        object.send("#{attr}=", value)
      end
    end

    # For each relationship specified in the relationships hash and defined on
    # the Resource, find the underlying object and assign it to the *object*
    # relationship.
    #
    # Example:
    #   class Person
    #     has_many :articles
    #   end
    #
    #   class Article
    #     belongs_to :person
    #   end
    #
    # With this relationship hash on article update/create:
    #   {
    #     person: {
    #       data: { id: '1', type: 'people' }
    #     }
    #   }
    #
    # This method would find the Person object identified by id *1* and
    # assign it to the instance of *article*
    #
    # Going the other way, given the following relationship hash when
    # creating/updating a person:
    #   {
    #     articles {
    #       data: [{id: '1', type: 'articles'}]
    #     }
    #   }
    #
    # This method would find the article identified by id *1* and _append_
    # that article to the *articles* relationship on the dynamically found
    # *person* object
    #
    # @raise [UnknownRelationshipError] raised if the `resource` does not
    #   define the given relationship
    def assign_relationships
      relationships.each do |rel|
        next if rel.blank?
        json_api_relationship = resource.relationships.detect do |relationship|
          relationship.name == rel[:name].to_s
        end
        unless json_api_relationship
          message = "`#{resource.class}' does not have relationship " \
                    "`#{rel[:name].to_s.gsub('=', '')}'"
          raise UnknownRelationshipError.new(message)
        end
        relationship_value =
          if json_api_relationship.cardinality == :many
            # cast to an array to prevent assigning `null` to an ActiveRecord
            # to-many relationship
            rel[:relations].to_a
          else
            # no need to cast potential `null`s, since an ActiveRecord to-one
            # can be set to `null`
            rel[:relations]
          end
        check_method("#{rel[:name]}=", relationship: true)
        object.send("#{rel[:name]}=", relationship_value)
      end
    end

    # Check if *object* responds to a specific method. Raise an error if it
    # doesn't
    #
    # @param method_name [String] The name of the method we're checking
    #
    # @raise [UnknownRelationshipError] if the relationship specified by
    #   *method_name* does not exist on the object
    # @raise [UnknownAttributeError] if the attribute specified by
    #   *method_name* does not exist on the object
    def check_method(method_name, relationship: false)
      return if object.respond_to?(method_name)

      # looking for setter attributes and relationships
      message = "`#{object.class}' does not have %{what} `#{method_name.to_s.gsub('=', '')}'"
      if relationship
        fail UnknownRelationshipError.new(message % {what: :relationship})
      else
        fail UnknownAttributeError.new(message % {what: :attribute})
      end
    end

    # Parse through the relationships object and returns an instance of a
    # class specified by *type*
    #
    # Given the following relationships structure:
    #   {
    #     person: {
    #       data: { id: '1', type: 'people' }
    #     }
    #   }
    #
    # This method will call
    #   Person.find_by_id('1')
    #
    # @return [Array] An array representing the method to be called on
    #   *object* and the objects found
    #     { name: :person, relations: [discovered_object] }
    def relationships
      @relationships.flat_map do |relationship_name, rel|
        next unless rel.key?(:data)
        if rel[:data].nil?
          {name: relationship_name, relations: nil}
        elsif rel[:data].blank?
          {name: relationship_name, relations: []}
        else
          created_objects = if rel[:data].is_a?(Array)
            rel[:data].map do |nested_rel|
              next if nested_rel.blank?
              validate_relationship_hash(nested_rel)
              self.class.new({data: nested_rel}).object
            end
          else
            validate_relationship_hash(rel[:data])
            self.class.new(rel).object
          end
          {name: relationship_name, relations: created_objects}
        end
      end
    end

    # Validates that the specified hash has both an id and a type
    #
    # @param [Hash] rel_hash The hash that will be validated
    def validate_relationship_hash(rel_hash)
      validation = { id: 'string', type: 'string' }
      validator = HashValidator.validate(rel_hash, validation)
      check_validation_errors(validator)
    end

    # Ensures that the validator has no errors. If the validator has errors,
    # they'll be stringified and passed in as the message to
    # {ValidationError}
    #
    # @param [HashValidator] validator The *validator* object that will be
    #   checked for errors
    def check_validation_errors(validator)
      error_template = "Field `%{field_name}' is malformed or missing"
      errors = validator.errors.each_with_object([]) do |(attr, _), result|
        result << error_template % {field_name: attr}
      end
      fail ValidationError.new(errors.join(', ')) if errors.present?
    end

    # Inspects the model using `attribute_names` and selects the attributes
    # which are also present in the Resource's `fields_array`. Alternatively,
    # properties from the model can be permitted, and will also be returned.
    #
    # @return [Array<String>] list of attributes available to assign to the
    # underlying model
    def assignable_attribute_names
      stored_attributes = object.attribute_names.select &method(:permitted?)
      transient_attributes = permitted.select do |attribute_name|
        check_method("#{attribute_name}=")
        true
      end.map(&:to_s)
      stored_attributes + transient_attributes
    end

    # Instanciates a Resource built with `object`
    #
    # @return [Resource]
    def resource
      @resource ||= resource_klass.new object
    end

    # Resolves the Resource class for `object`
    #
    # @return [Resource] the resolved Resource class for `object`
    def resource_klass
      @resource_klass ||= JsonApi::Resources::Discovery
        .resource_for_name object,
                           resource_class: @resource_class
    end

    # Checks for the attribute's presence in the Resource's fields array or the
    # permitted whitelist
    def permitted?(attribute_name)
      resource.fields_array.include?(attribute_name.to_sym) ||
      permitted.include?(attribute_name.to_sym)
    end
  end
end
