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
      
      if options[:attributes].try(:any?)
        attributes.slice!(*options[:attributes])
      end
      
      if options[:map_attributes].try(:is_a?, Proc)
        attributes = Hash[attributes.map do |key, value|
          options[:map_attributes].call(key, value).to_a.flatten
        end]
      elsif options[:map_attributes].try(:is_a?, Symbol) and respond_to?(options[:map_attributes])
        attributes = Hash[attributes.map do |key, value|
          object.send(options[:map_attributes], key, value).to_a.flatten
        end]
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
        if value.class.compact_xml_config[:block]
          inline_and_block_attributes[:block][key] = value
        else
          inline_and_block_attributes[:inline][key] = value
        end
      end
      
      inline_and_block_attributes[:inline].each do |key, value|
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
          markup_string << %Q(<#{key} type="array">)
          markup_string << recursive_compact_xml_markup(value)
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