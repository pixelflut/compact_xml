module CompactXml
  
  require 'compact_xml/active_model/base'
  require 'compact_xml/builder'
  
  if defined? Rails
    class CompactXmlRailtie < ::Rails::Railtie
      Mime::Type.register "text/cxml", :cxml
  
      config.after_initialize do
        require 'action_controller/metal/renderers'
        
        ActionController.add_renderer :cxml do |data, options|
          self.content_type ||= Mime::XML
          
          if data.respond_to?(:to_compact_xml)
            data.to_compact_xml
          else
            data
          end
        end
      end
    end
  end
  
end