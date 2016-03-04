module JsonApiRails
  # Namespace for helpers to be used in `ActionController::Base` descendants.
  module ControllerHelpers
    # Prepares included relationship names for use in JsonApi.serialize. It
    # expects a list of symbols.
    # @return [Array] list of symbolized relationship names
    def includes
      StringToIncludes.build params.fetch(:include, '')
    end

    # Parses `params_hsh` and passes the resulting model to the given block.
    # Rescues and renders any errors encountered when parsing.
    def parse_json_api_params(params_hsh, ar_relation: nil, resource_class: nil, permitted: [], &block)
      parser = Parser.new params_hsh, ar_relation, resource_class, permitted
      parser.execute block
    rescue Error => exception
      render json_api_errors: [exception.message]
    end

    # Handles parsing a string of relationship names into an object suitable for
    # use in JsonApi.serialize and ActiveRecord::QueryMethods#includes.
    class StringToIncludes
      attr_reader :string

      def self.build(string)
        instance = new string
        instance.build
      end

      def initialize(string)
        @string = string
      end

      def build
        split = string.gsub(' ', '').split(',')
        # builds an array of unique relationship names, including if there are
        # multiple layers of nesting.
        #
        # ex: for ['foo', 'foo.bar', 'foo.bar.baz'] this evaluates to ['foo.bar.baz']
        relationship_names = split.each_with_object([]) do |relationship_name, ary|
          other_relationships = split.reject { |rel| rel == relationship_name }
          unless ary.include?(relationship_name) ||
                 other_relationships.any? { |s| s.include?(relationship_name) && s.length > relationship_name.length }
            ary << relationship_name
          end
          ary
        end
        deeply_nested, non_nested = relationship_names.partition &method(:deeply_nested?)
        nested_data               = deeply_nested.map &method(:to_relationship)
        non_nested_names          = non_nested.map &:to_sym
        non_nested_names + nested_data
      end

      def to_relationship(relationship_string)
        relationship_names = relationship_string.split('.')
        hashify_relationship({}, relationship_names)
      end

      def deeply_nested?(relationship_name)
        relationship_name.include? '.'
      end

      def hashify_relationship(hash, relationship_names)
        last_two, remaining = relationship_names.partition { |name| relationship_names.slice(-2..-1).include? name }
        if hash.any?
          hash = { last_two.last.to_sym => hash }
          remaining = last_two[0..-2]
        else
          hash[last_two.first.to_sym] = last_two.last.to_sym
        end

        case remaining.count
        when 1 then { remaining.first.to_sym => hash }
        when 0 then hash
        else hashify_relationship(hash, remaining)
        end
      end
    end
  end
end
