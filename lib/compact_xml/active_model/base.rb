if defined? ActiveModel
  
  module ActiveModel
    class Base
      include ActiveModel::Model
      
      attr_reader :attributes
      
      def initialize(attributes = {})
        @attributes = attributes
      end
      
      def id;         attributes['id'] || attributes['_id']; end
      def id=(value); attributes['id'] = value;              end
      
      def method_missing(name, *args, &block)
        attributes[name.to_sym] || attributes[name.to_s] || super
      end
      
      def persisted?; true; end
      def save;       true; end
      
    end
  end
  
end