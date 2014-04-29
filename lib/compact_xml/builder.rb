module CompactXml
  module Builder
    
    CompactXmlVersionHead1 = '<?xml version="1.0" encoding="utf-8"?>'
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    def to_compact_xml
      cxml_string = ''
      cxml_string << CompactXmlVersionHead1
      cxml_string << recursive_compact_xml_markup(self)
      cxml_string
    end
    
    def recursive_compact_xml_markup(object, root_tag = nil)
      options = object.class.compact_xml_config
      
      root_tag ||= options[:root]
      
      if object.is_a?(ActiveRecord::Relation)
        object = object.to_a
      end
      
      attributes = {}
      if object.class.ancestors.include?(ActiveRecord::Base)
        attributes = object.attributes
      elsif object.class.ancestors.include?(ActiveModel::Base)
        attributes = object.attributes
      elsif object.is_a?(Array)
        root_tag ||= object.first.class.name.to_s.camelize(:lower).pluralize
        attributes = object.map do |value|
          ["#{value.class.name}-#{value.object_id}", value]
        end
      elsif object.is_a?(Hash)
        attributes = object
      else
        attributes = {value: object.to_s}
      end
      
      if options[:attributes]
        options[:attributes] = [options[:attributes]].flatten
        options[:attributes].map!(&:to_sym)
        attributes.symbolize_keys!
        
        options[:attributes].each do |attribute_or_accessor|
          attribute_or_accessor = attribute_or_accessor.to_sym
          
          unless attributes.has_key?(attribute_or_accessor)
            attributes[attribute_or_accessor] = object.send(attribute_or_accessor)
          end
        end
        
        if options[:attributes].any?
          attributes.slice!(*options[:attributes])
        end
      end
      
      if options[:map_attributes]
        [options[:map_attributes]].flatten.each do |proc_or_method|
          if proc_or_method.is_a?(Proc)
            attributes = Hash[attributes.map do |key, value|
              proc_or_method.call(key, value).to_a.flatten
            end]
          elsif proc_or_method.is_a?(Symbol) and object.respond_to?(proc_or_method)
            attributes = Hash[attributes.map do |key, value|
              object.send(proc_or_method, key, value).to_a.flatten
            end]
          end
        end
      end

      root_tag ||= object.class.name.camelize(:lower)
      root_tag = ERB::Util.html_escape(root_tag)
      
      inline_element = true
      
      markup_string = ''
      markup_string << "<#{root_tag}"
      
      if object.is_a?(Array)
        markup_string << ' type="array"'
      end
      
      inline_and_block_attributes = {}
      inline_and_block_attributes[:inline] = {}
      inline_and_block_attributes[:block] = {}
      
      attributes.select do |key, value|
        if not value.blank? or value.is_a?(FalseClass)
          if value.class.compact_xml_config[:block]
            inline_and_block_attributes[:block][key] = value
          else
            inline_and_block_attributes[:inline][key] = value
          end
        end
      end
      
      inline_and_block_attributes[:inline].each do |key, value|
        if value.is_a?(Time)
          value = value.to_i
        end
        
        if value.is_a?(TrueClass)
          value = 1
        end
        
        if value.is_a?(FalseClass)
          value = 0
        end
        
        key = ERB::Util.html_escape(key.to_s.camelize(:lower))
        value = ERB::Util.html_escape(value)
        
        markup_string << %Q( #{key}="#{value}")
      end
      
      inline_and_block_attributes[:block].each do |key, value|
        key = key.to_s.camelize(:lower)
        if inline_element
          markup_string << '>'
          inline_element = false
        end
        
        if value.is_a?(Array)
          markup_string << %Q(<#{key.pluralize} type="array">)
          value.each do |v|
            markup_string << recursive_compact_xml_markup(v, key.singularize)
          end
          markup_string << %Q(</#{key}>)
        else
          markup_string << recursive_compact_xml_markup(value)
        end
      end
      
      if inline_element
        markup_string << "/>"
      else
        markup_string << "</#{root_tag}>"
      end
      
      markup_string
    end
    
    module ClassMethods
      
      def compact_xml_config(options = nil)
        if options and options.try(:any?)
          @compact_xml_config = {}
          if self.respond_to?(:compact_xml_default_config)
            @compact_xml_config = compact_xml_default_config || {}
          end
          @compact_xml_config.deep_merge!(options)
        else
          if self.respond_to?(:compact_xml_default_config)
            @compact_xml_config || compact_xml_default_config || {}
          else
            @compact_xml_config || {}
          end
        end
      end
      
    end
    
  end
end

Object.send(:include, CompactXml::Builder)

Array.send(:define_singleton_method, :compact_xml_default_config) do
  {block: true}
end

Hash.send(:define_singleton_method, :compact_xml_default_config) do
  {block: true}
end

if ActiveModel
  ActiveModel::Base.send(:define_singleton_method, :compact_xml_default_config) do
    {block: true}
  end
end

if ActiveRecord
  ActiveRecord::Base.send(:define_singleton_method, :compact_xml_default_config) do
    {block: true}
  end
end