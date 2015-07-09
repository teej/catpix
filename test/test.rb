require './lib/gif'

file = ARGV[0]

gif = Catpix::Gif.read(file)



puts "global_color_table_flag #{gif.global_color_table_flag}"
puts "color_resolution #{gif.color_resolution}"
puts "sort_flag #{gif.sort_flag}"
puts "global_color_table_size #{gif.global_color_table_size}"

puts "bg_color_index #{gif.bg_color_index}"
puts "pixel_aspect_ratio #{gif.pixel_aspect_ratio}"

puts "canvas #{gif.canvas_width} x #{gif.canvas_height}" 

puts "global color table #{gif.global_color_table.size}"

gif.images.each do |image|
  puts "Image #{image}"
end

puts 'done'