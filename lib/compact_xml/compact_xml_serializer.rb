if defined? ActiveModel
  require 'active_model/serializers/xml'

  module CompactXml
    module ActiveModel
      module InstanceMethods
    
        def compact_xml_root_attribute_name
          self.class.compact_xml_root_attribute_name
        end
        
        def to_compact_xml(options = {}, &block)
          options[:compact_xml_map_attributes] ||= {}
          options[:compact_xml_map_attributes].deep_merge!(self.class.compact_xml_map_attributes)
          
          options[:except] ||= []
          options[:except] += self.class.compact_xml_get_except_attributes
          
          serializer = CompactXml::CompactXmlSerializer.new(self, options).serialize(&block)
        end
      
      end
    end
    
    module ActiveModel
      module ClassMethods
        
        def compact_xml_root_attribute_name
          @compact_xml_root_attribute || self.model_name.element
        end

        def compact_xml_root_attribute(root_attribute_name)
          @compact_xml_root_attribute = root_attribute_name
        end
              
        def compact_xml_map_attribute(old_attribute, new_attribute_name)
          compact_xml_map_attributes[old_attribute.to_sym] = new_attribute_name.to_s
        end
        
        def compact_xml_map_attributes
          @compact_xml_map_attributes ||= {}
        end
        
        def compact_xml_except_attributes(*args)
          @compact_xml_except_attributes = args.to_a.flatten
        end
        
        def compact_xml_get_except_attributes(*args)
          @compact_xml_except_attributes ||= []
        end
      
      end
    end

    class CompactXmlSerializer < ::ActiveModel::Serializers::Xml::Serializer
    
      def add_attributes(args)
        options[:subobjects] ||= []

        serializable_collection.collect do |attribute|
          key = ActiveSupport::XmlMini.rename_key(options[:compact_xml_map_attributes][attribute.name.to_sym] || attribute.name, options).camelize(:lower)

          if attribute.value != "null"
            if attribute.value.respond_to?(:to_model) && attribute.value.to_model.respond_to?(:to_compact_xml)
              options[:subobjects] << attribute
            else
              case attribute.value
              when Array
                options[:subobjects] << attribute
              when Hash
                options[:subobjects] << attribute
              when Time
                value = attribute.value.to_i
              when NilClass
                value = nil
              else
                value = attribute.value.to_s
              end
              args << {key => value} unless value.nil? and !options[:skip_ignore_nil]
            end
          end
        end
      end
    
      def add_associations(association, records, opts)
        if records.is_a?(Enumerable)
          tag = ActiveSupport::XmlMini.rename_key(options[:compact_xml_map_attributes][association.to_sym] || association.to_s, opts).camelize(:lower)
          type = options[:skip_types] ? {} : {type: "array"}

          if records.empty?
            @builder.tag!(tag, type)
          else
            @builder.tag!(tag, type) do
              association_name = association.to_s.singularize
              records.each do |record|
                if options[:skip_types]
                  record_type = {}
                else
                  record_class = (record.class.to_s.underscore == association_name) ? nil : record.class.name
                  record_type = {type: record_class}
                end
                
                record.to_compact_xml opts.merge(root: association_name, skip_instruct: true).merge(record_type)
              end
            end
          end
        else
          if record = @serializable.send(association)
            record.to_compact_xml(opts.merge(root: association_name, skip_instruct: true))
          end
        end
      end
    
      def serialize
        options[:camelcase] = options.has_key?(:camelcase) ? options[:camelcase] : true
        options[:indent]  ||= 2
        options[:builder] ||= ::PxBuilder::XmlMarkup.new(indent: options[:indent], camelcase: options[:camelcase])
        
        root = (options[:root] || @serializable.compact_xml_root_attribute_name).to_s

        root = ActiveSupport::XmlMini.rename_key(root, options)
        
        args = [root]
        if options[:namespace]
          args << {xmlns: options[:namespace]}
        end

        if options[:type]
          args << {type: options[:type]}
        end
        
        add_attributes(args)

        @builder = options[:builder]
        @builder.instruct! unless options[:skip_instruct]
        @builder.tag!(*args) do
          if subobjects = options.delete(:subobjects)
            subobjects.each do |attribute|
              key = ActiveSupport::XmlMini.rename_key(options[:compact_xml_map_attributes][attribute.name.to_sym] || attribute.name, options)
              if attribute.value != "null"
                if attribute.value.respond_to?(:to_model) && attribute.value.to_model.respond_to?(:to_compact_xml)
                  attribute.value.to_model.to_compact_xml(options.merge({root: key, skip_instruct: true}))
                else
                  case attribute.value
                  when Array
                    attribute.value.to_compact_xml(options.merge({root: key, children: key.to_s.singularize, skip_instruct: true}))
                  when Hash
                    attribute.value.to_compact_xml(options.merge({root: key, skip_instruct: true}))
                  end
                end
              end
            end
          end
        
          procs = options.delete(:procs)
          @serializable.send(:serializable_add_includes, options) { |association, records, opts|
            add_associations(association, records, opts)
          }
          options[:procs] = procs
          add_procs
          yield @builder if block_given?
        end

      end #serialize
    
    end #CompactXmlSerializer
      
  end

  ActiveModel::Base.send(:include, CompactXml::ActiveModel::InstanceMethods)
  ActiveModel::Base.send(:extend, CompactXml::ActiveModel::ClassMethods)
  
  if defined? ActiveRecord
    ActiveRecord::Base.send(:include, CompactXml::ActiveModel::InstanceMethods)
    ActiveRecord::Base.send(:extend, CompactXml::ActiveModel::ClassMethods)
  end
  
end