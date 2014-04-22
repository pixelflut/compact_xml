#!/usr/bin/env ruby

# The XChar library is provided courtesy of Sam Ruby (See
# http://intertwingly.net/stories/2005/09/28/xchar.rb)

# --------------------------------------------------------------------

# If the Builder::XChar module is not currently defined, fail on any
# name clashes in standard library classes.

module PxBuilder
  def self.check_for_name_collision(klass, method_name, defined_constant=nil)
    if klass.method_defined?(method_name.to_s)
      fail RuntimeError,
	"Name Collision: Method '#{method_name}' is already defined in #{klass}"
    end
  end
end

if ! defined?(PxBuilder::XChar) and ! String.method_defined?(:encode)
  PxBuilder.check_for_name_collision(String, "to_xmls")
  PxBuilder.check_for_name_collision(Fixnum, "xmlchr")
end

######################################################################
module PxBuilder

  ####################################################################
  # XML Character converter, from Sam Ruby:
  # (see http://intertwingly.net/stories/2005/09/28/xchar.rb). 
  #
  module XChar # :nodoc:

    # See
    # http://intertwingly.net/stories/2004/04/14/i18n.html#CleaningWindows
    # for details.
    if !const_defined?(:CP1252)
      CP1252 = {			# :nodoc:
        128 => 8364,		# euro sign
        130 => 8218,		# single low-9 quotation mark
        131 =>  402,		# latin small letter f with hook
        132 => 8222,		# double low-9 quotation mark
        133 => 8230,		# horizontal ellipsis
        134 => 8224,		# dagger
        135 => 8225,		# double dagger
        136 =>  710,		# modifier letter circumflex accent
        137 => 8240,		# per mille sign
        138 =>  352,		# latin capital letter s with caron
        139 => 8249,		# single left-pointing angle quotation mark
        140 =>  338,		# latin capital ligature oe
        142 =>  381,		# latin capital letter z with caron
        145 => 8216,		# left single quotation mark
        146 => 8217,		# right single quotation mark
        147 => 8220,		# left double quotation mark
        148 => 8221,		# right double quotation mark
        149 => 8226,		# bullet
        150 => 8211,		# en dash
        151 => 8212,		# em dash
        152 =>  732,		# small tilde
        153 => 8482,		# trade mark sign
        154 =>  353,		# latin small letter s with caron
        155 => 8250,		# single right-pointing angle quotation mark
        156 =>  339,		# latin small ligature oe
        158 =>  382,		# latin small letter z with caron
        159 =>  376,		# latin capital letter y with diaeresis
      }
    end
    
    
    # See http://www.w3.org/TR/REC-xml/#dt-chardata for details.
    if !const_defined?(:PREDEFINED)
      PREDEFINED = {
        38 => '&amp;',		# ampersand
        60 => '&lt;',		# left angle bracket
        62 => '&gt;',		# right angle bracket
        9  => '&#x9;',  # tab
        10 => '&#xA;'   # newline
      }
    end

    # See http://www.w3.org/TR/REC-xml/#charsets for details.
    if !const_defined?(:VALID)
      VALID = [
        0x9, 0xA, 0xD,
        (0x20..0xD7FF), 
        (0xE000..0xFFFD),
        (0x10000..0x10FFFF)
      ]
    end

    # http://www.fileformat.info/info/unicode/char/fffd/index.htm
    if !const_defined?(:REPLACEMENT_CHAR)
      REPLACEMENT_CHAR =
        if String.method_defined?(:encode)
          "\uFFFD"
        elsif $KCODE == 'UTF8'
          "\xEF\xBF\xBD"
        else
          '*'
        end
      end
    end

end


if String.method_defined?(:encode)
  module PxBuilder
    module XChar # :nodoc:
      CP1252_DIFFERENCES, UNICODE_EQUIVALENT = PxBuilder::XChar::CP1252.each.
        inject([[],[]]) {|(domain,range),(key,value)|
          [domain << key,range << value]
        }.map {|seq| seq.pack('U*').force_encoding('utf-8')}
  
      XML_PREDEFINED = Regexp.new('[' +
        PxBuilder::XChar::PREDEFINED.keys.pack('U*').force_encoding('utf-8') +
      ']')
  
      INVALID_XML_CHAR = Regexp.new('[^'+
        PxBuilder::XChar::VALID.map { |item|
          case item
          when Fixnum
            [item].pack('U').force_encoding('utf-8')
          when Range
            [item.first, '-'.ord, item.last].pack('UUU').force_encoding('utf-8')
          end
        }.join +
      ']')
  
      ENCODING_BINARY = Encoding.find('BINARY')
      ENCODING_UTF8   = Encoding.find('UTF-8')
      ENCODING_ISO1   = Encoding.find('ISO-8859-1')

      # convert a string to valid UTF-8, compensating for a number of
      # common errors.
      def XChar.unicode(string)
        if string.encoding == ENCODING_BINARY
          if string.ascii_only?
            string
          else
            string = string.clone.force_encoding(ENCODING_UTF8)
            if string.valid_encoding?
              string
            else
              string.encode(ENCODING_UTF8, ENCODING_ISO1)
            end
          end

        elsif string.encoding == ENCODING_UTF8
          if string.valid_encoding?
            string
          else
            string.encode(ENCODING_UTF8, ENCODING_ISO1)
          end

        else
          string.encode(ENCODING_UTF8)
        end
      end

      # encode a string per XML rules
      def XChar.encode(string)
        unicode(string).
          tr(CP1252_DIFFERENCES, UNICODE_EQUIVALENT).
          gsub(INVALID_XML_CHAR, REPLACEMENT_CHAR).
          gsub(XML_PREDEFINED) {|c| PREDEFINED[c.ord]}
      end
    end
  end

else

  ######################################################################
  # Enhance the Fixnum class with a XML escaped character conversion.
  #
  class Fixnum
    PxXChar = PxBuilder::XChar if ! defined?(PxXChar)
  
    # XML escaped version of chr. When <tt>escape</tt> is set to false
    # the CP1252 fix is still applied but utf-8 characters are not
    # converted to character entities.
    def xmlchr(escape=true)
      n = PxXChar::CP1252[self] || self
      case n when *PxXChar::VALID
        PxXChar::PREDEFINED[n] or 
          (n<128 ? n.chr : (escape ? "&##{n};" : [n].pack('U*')))
      else
        PxBuilder::XChar::REPLACEMENT_CHAR
      end
    end
  end
  

  ######################################################################
  # Enhance the String class with a XML escaped character version of
  # to_s.
  #
  class String
    # XML escaped version of to_s. When <tt>escape</tt> is set to false
    # the CP1252 fix is still applied but utf-8 characters are not
    # converted to character entities.
    def to_xmls(escape=true)
      unpack('U*').map {|n| n.xmlchr(escape)}.join # ASCII, UTF-8
    rescue
      unpack('C*').map {|n| n.xmlchr}.join # ISO-8859-1, WIN-1252
    end
  end
end
