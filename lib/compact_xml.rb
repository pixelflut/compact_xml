module CompactXml
  require 'compact_xml/px_builder/px_blankslate'
  require 'compact_xml/px_builder/px_xchar'
  require 'compact_xml/px_builder/px_xmlbase'
  require 'compact_xml/px_builder/px_xmlmarkup'

  require 'compact_xml/array'
  require 'compact_xml/hash'

  if defined? Rails
    require 'compact_xml/compact_xml_serializer'

    class CompactXmlRailtie < ::Rails::Railtie
  
      Mime::Type.register "text/cxml", :cxml
  
      config.after_initialize do
        require 'action_controller/metal/renderers'
        
        ActionController.add_renderer :cxml do |data, options|
          self.content_type ||= options[:content_type] || Mime::CXML
          
          if data.respond_to?(:to_compact_xml)
            data.to_compact_xml(options)
          else
            data
          end
        end
      end
  
    end
  end
end