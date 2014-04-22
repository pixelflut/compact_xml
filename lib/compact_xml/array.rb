require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/inflector'

class Array
  
  def to_compact_xml(options = {})
    options = options.dup
    options[:root]     ||= all? { |e| e.is_a?(first.class) && first.class.to_s != "Hash" } ? ActiveSupport::Inflector.pluralize(ActiveSupport::Inflector.underscore(first.respond_to?(:compact_xml_root_attribute_name) ? first.compact_xml_root_attribute_name : first.class.name)).tr('/', '_') : "records"
    options[:root]  =  options[:root].to_s
    options[:children] ||= options[:root].to_s.singularize
    options[:indent]   ||= 2
    options[:builder]  ||= PxBuilder::XmlMarkup.new(indent: options[:indent], camelcase: options[:camelcase])

    root     = options.delete(:root).to_s
    children = options.delete(:children)

    if !options.has_key?(:dasherize) || options[:dasherize]
      root = root.dasherize
    end

    options[:builder].instruct! unless options.delete(:skip_instruct)

    opts = options.merge({root: children})

    xml = options[:builder]
    if empty?
      xml.tag!(root, options[:skip_types] ? {} : {type: "array"})
    else
      xml.tag!(root, options[:skip_types] ? {} : {type: "array"}) {
        each do |e|
          if e.respond_to?(:to_compact_xml)
             e.to_compact_xml(opts.merge({skip_instruct: true})) 
          else
            xml.tag!(children, e.to_s)
          end
        end
      }
    end
  end
  
end
