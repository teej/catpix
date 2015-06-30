require './lib/gif'

file = 'test.gif'

image = Catpix::Gif.read(file)



puts "global_color_table_flag #{image.global_color_table_flag}"
puts "color_resolution #{image.color_resolution}"
puts "sort_flag #{image.sort_flag}"
puts "global_color_table_size #{image.global_color_table_size}"

puts "bg_color_index #{image.bg_color_index}"
puts "pixel_aspect_ratio #{image.pixel_aspect_ratio}"

puts "canvas #{image.width} x #{image.height}" 

puts "global color table #{image.global_color_table.size}"

puts 'done'