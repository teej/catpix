require './lib/gif/color' #TODO: Fix this

def print_bytes(section, byte_str)
  puts "#{section} => #{bytes_to_string(byte_str)}"
end

def bytes_to_string(byte_str)
  byte_str.bytes.map{ |b| b.to_s(16)}.join(' ')
end

module Catpix
  class Gif

    attr_accessor :canvas_width, :canvas_height,
      :images,

      # Packed Field
      :global_color_table_flag, :color_resolution, :sort_flag, :global_color_table_size,

      :bg_color_index, :pixel_aspect_ratio,

      :global_color_table,

      :file_data_buffer

    HEADER_LENGTH = 6
    LOGICAL_SCREEN_DESCRIPTOR_LENGTH = 7

    EXTENTION_INTRODUCER = '21'
    # Extension Labels
    COMMENT_LABEL = 'fe'
    GRAPHIC_CONTROL_LABEL = 'f9'

    BLOCK_TERMINATOR = '0'

    IMAGE_SEPERATOR = '2c'

    def self.read(filename)
      # returns Catpix::Gif
      # Read in the file
      # create new gif object

      file = File.open(filename)
      Catpix::Gif.new(file.read)
    end

    def initialize(image_data)

      self.images = []

      self.file_data_buffer = image_data

      print_bytes('entire image', image_data)

      # print_bytes "Image", image_data

      header = parse_header(file_data_buffer.slice!(0...HEADER_LENGTH))

      logical_screen_descriptor = parse_logical_screen_descriptor(file_data_buffer.slice!(0...LOGICAL_SCREEN_DESCRIPTOR_LENGTH))

      if (self.global_color_table_flag)
        self.global_color_table = []
        global_color_table_byte_length = global_color_table_size * 3  #- 8
        # puts "global_color_table_size => #{global_color_table_size}"
        # puts "global_color_table_byte_length => #{global_color_table_byte_length}"
        parse_global_color_table(file_data_buffer.slice!(0...global_color_table_byte_length))
      end

      last_block = nil

      while file_data_buffer.size > 0

        block_header = file_data_buffer.slice!(0)

        current_block = bytes_to_string(block_header)

        puts "Start of block [#{current_block}]"

        if last_block == IMAGE_SEPERATOR
          # do stuff
          puts "Check for image data"
          parse_image_data()
          
        else
          case current_block
            when EXTENTION_INTRODUCER
            then 
              puts "EXTENTION_INTRODUCER"
              extension_label = bytes_to_string(file_data_buffer.slice!(0))
              puts "Label: #{extension_label}"
              case extension_label
                when COMMENT_LABEL
                then
                  puts "Comment Block found"
                  parse_comment_block()
                when GRAPHIC_CONTROL_LABEL
                  puts "Graphic Control Block found"
                  parse_graphic_control_block()
              end
            when IMAGE_SEPERATOR
            then
              puts "Image Block found"
              parse_image_descriptor(file_data_buffer.slice!(0..8))
            else
              break
          end
        end

        last_block = current_block

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

      self.canvas_width  = parse_unsigned(_width)
      self.canvas_height = parse_unsigned(_height)

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

    def parse_comment_block()
      bytes = 0
      while bytes_to_string(file_data_buffer.slice!(0)) != BLOCK_TERMINATOR
        bytes +=1
      end
      puts "Found #{bytes} bytes in comment"
    end

    def parse_graphic_control_block()
      file_data_buffer.slice!(0..4)
      last_byte_in_block = bytes_to_string(file_data_buffer.slice!(0))
      unless last_byte_in_block == BLOCK_TERMINATOR
        raise "Graphic Control Block incorrectly terminated #{last_byte_in_block}" 
      end
    end


    def parse_image_descriptor(image_descriptor_bytes)
      print_bytes("image_descriptor_bytes", image_descriptor_bytes)

      _image = {}

      _image['left']   = parse_unsigned(image_descriptor_bytes.slice!(0..1))
      _image['top']    = parse_unsigned(image_descriptor_bytes.slice!(0..1))
      _image['width']  = parse_unsigned(image_descriptor_bytes.slice!(0..1))
      _image['height'] = parse_unsigned(image_descriptor_bytes.slice!(0..1))
      _packed_field = image_descriptor_bytes.slice!(0)

      print_bytes('_packed_field', _packed_field)

      self.images << _image

    end

    def parse_image_data()

      while (data_sub_block_header = bytes_to_string(file_data_buffer.slice!(0))) != BLOCK_TERMINATOR
        
        block_size = data_sub_block_header.to_i(16)
        puts "data sub block #{block_size}"
        data_sub_block = file_data_buffer.slice!(0...block_size)
        puts "data_sub_block => #{data_sub_block.bytes.join(' ')}"
        # puts "data_sub_block => #{data_sub_block.bytes.join(' ')}"
        data_sub_block.bytes.each do |byte|
          bit_array = parse_byte_to_bit_array(byte.to_s)
          while bit_array.length > 0
            color_data = bit_array.shift(4)
            puts "color_data #{color_data.join.to_i(4)}"
          end
        end
        
      end

    end

  end
end