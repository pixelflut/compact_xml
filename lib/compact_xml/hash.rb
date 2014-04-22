class Hash
  
  def to_compact_xml(options = {})
    options = options.dup
    options[:indent] ||= 2
    options = {
      builder: PxBuilder::XmlMarkup.new(indent: options[:indent], camelcase: options[:camelcase]), root: "hash"
    }.merge(options)
    options[:builder].instruct! unless options.delete(:skip_instruct)

    attributes = {}
    subarrays = {}
    each do |key, value|
      next if not options[:except].blank? and options[:except].to_a.index(key.to_sym) != nil
      key = key.to_s
      if value.respond_to?(:to_model) && value.to_model.respond_to?(:to_compact_xml)
        subarrays[key] = value.to_model
      elsif value.is_a?(Enumerable) && value.is_a?(Array)
        subarrays[key] = value.to_a
      else
        case value
          when ::Hash
            subarrays[key] = value
          when ::Array
            subarrays[key] = value
          when ::Method, ::Proc
            attributes[key] = value.call()
          when ::Time
            attributes[key] = value.xmlschema
          when ::NilClass
            attributes[key] = nil unless options[:ignore_nil]
          else
            attributes[key] = value
        end
      end
    end

    
    xml = options[:builder]
    
    if subarrays.blank?
      xml.__send__(:method_missing, options[:root], attributes)
    else
      xml.__send__(:method_missing, options[:root], attributes) do
        subarrays.each do |key, value|
          key = key.to_s
          if value.respond_to?(:to_model)
            value.to_compact_xml(options.merge({root: key, skip_instruct: true}))
          else
            case value
              when ::Hash
                value.to_compact_xml(options.merge({root: key, skip_instruct: true }))
              when ::Array
                value.to_compact_xml(options.merge({root: key, children: key.to_s.singularize, skip_instruct: true}))
            end
          end
        end
      end
    end
  end
end