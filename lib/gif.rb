require './lib/gif/color' #TODO: Fix this

module Catpix
  class Gif

    attr_accessor :width, :height,
      # Packed Field
      :global_color_table_flag, :color_resolution, :sort_flag, :global_color_table_size,

      :bg_color_index, :pixel_aspect_ratio,

      :global_color_table

    HEADER_LENGTH = 6
    LOGICAL_SCREEN_DESCRIPTOR_LENGTH = 7

    EXTENTION_INTRODUCER = '21'
    IMAGE_SEPERATOR = '2c'

    def self.read(filename)
      # returns Catpix::Gif
      # Read in the file
      # create new gif object

      file = File.open(filename)
      Catpix::Gif.new(file.read)
    end


    def print_bytes(section, byte_str)
      puts "#{section} => #{byte_str.bytes.map{ |b| b.to_s(16)}.join(' ')}"
    end

    def initialize(image_data)

      _image_data = image_data

      # print_bytes "Image", image_data

      header = parse_header(_image_data.slice!(0...HEADER_LENGTH))

      logical_screen_descriptor = parse_logical_screen_descriptor(_image_data.slice!(0...LOGICAL_SCREEN_DESCRIPTOR_LENGTH))

      if (self.global_color_table_flag)
        self.global_color_table = []
        global_color_table_byte_length = global_color_table_size * 3 - 8
        # puts "global_color_table_size => #{global_color_table_size}"
        # puts "global_color_table_byte_length => #{global_color_table_byte_length}"
        parse_global_color_table(_image_data.slice!(0...global_color_table_byte_length))
      end


      while _image_data.size > 0

        block_header = _image_data.slice!(0)

        print_bytes('block_header', block_header)

        case block_header.bytes.first.to_s
          when EXTENTION_INTRODUCER
          then 
            extension_label = _image_data.slice!(0).to_s(16)
            puts "EXTENTION_INTRODUCER #{extension_label}"


          when IMAGE_SEPERATOR
          then puts 'IMAGE_SEPERATOR'
        end



        


        break
      end

      # - parse the file format, reject if not gif
      # - split out the header, read color table, parse into pixels
    end

    def columns
    end

    def rows
    end

    def change_geometry()
    end

    def each_pixel()
    end

    def resize!
    end


    private
    def parse_header(header_data)
      raise "Invalid header length #{header_data.length}" unless header_data.length == HEADER_LENGTH

      print_bytes("header", header_data)

      signature = header_data.slice!(0..2)
      raise "Invalid signature for gif #{signature}" unless signature == 'GIF'

      version = header_data.slice!(0..2)
      raise "Invalid version for gif #{version}" unless version == '89a'
    end

    def parse_logical_screen_descriptor(lsd_data)
      raise "Invalid header length #{lsd_data.length}" unless lsd_data.length == LOGICAL_SCREEN_DESCRIPTOR_LENGTH

      print_bytes("logical_screen_descriptor", lsd_data)

      _width       = lsd_data.slice!(0..1)
      _height      = lsd_data.slice!(0..1)
      _packed_field       = lsd_data.slice!(0)
      _bg_color_index     = lsd_data.slice!(0)
      _pixel_aspect_ratio = lsd_data.slice!(0)

      self.width = parse_unsigned(_width)
      self.height = parse_unsigned(_height)

      parse_packed_field(_packed_field)

      self.bg_color_index = _bg_color_index.bytes
      self.pixel_aspect_ratio = _pixel_aspect_ratio.bytes

    end

    def parse_unsigned(unsigned_field)
      # 16-bit, nonnegative integer
      # little-endian format
      unsigned_field.unpack('S<').first
    end

    def parse_packed_field(packed_field)

      packed_field_byte = parse_byte_to_bit_array(packed_field)      
      raise "Packed field byte incorrect size #{packed_field_byte.length}" unless packed_field_byte.length == 8

      _global_color_table_flag = packed_field_byte.shift(1)
      _color_resolution        = packed_field_byte.shift(3)
      _sort_flag               = packed_field_byte.shift(1)
      _global_color_table_size = packed_field_byte.shift(3)

      self.global_color_table_flag = parse_global_color_table_flag(_global_color_table_flag)
      self.color_resolution = parse_color_resolution(_color_resolution)
      self.sort_flag = parse_sort_flag(_sort_flag)
      self.global_color_table_size = parse_global_color_table_size(_global_color_table_size)

    end

    # Takes a byte array, returns a boolean
    def parse_global_color_table_flag(_global_color_table_flag)
      (_global_color_table_flag.first == 1)
    end

    def parse_color_resolution(_color_resolution)
      (_color_resolution.join.to_i(2) + 1)
    end

    def parse_sort_flag(_sort_flag)
      (_sort_flag.first == 1)
    end

    def parse_global_color_table_size(_global_color_table_size)
      (2 ** (_global_color_table_size.join.to_i(2) + 1))
    end

    def parse_byte_to_bit_array(byte)
      byte.unpack('B*').first.split('').map(&:to_i)
    end


    def parse_global_color_table(global_color_table_data)

      # unless global_color_table_data.length == global_color_table_size * 3
      #   raise "Global color table not long enough #{global_color_table_data.length}" 
      # end

      global_color_table_data = global_color_table_data.bytes

      while global_color_table_data.size > 0
        color_data = global_color_table_data.shift(3)
        color = parse_color(color_data)
        self.global_color_table << color
      end

    end

    def parse_color(color_data)
      # puts color_data.unpack('C')
      Color(*color_data)
    end

  end
end