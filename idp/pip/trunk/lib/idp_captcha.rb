# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# A lot of this was ripped from http://frankhale.org/CAPTCHA_RoR_Tutorial.html
require 'RMagick'

class IdpCaptcha
  @@captcha_dir = 'public/images/captcha' unless defined? @@captcha_dir
  
  def self.captcha_dir=( cd ); @@captcha_dir = cd; end

  attr_reader :filename, :code
  
  def initialize(length = 5)
    @key = ('A'..'Z').to_a
    
    @white = [255, 255, 255]
    @black = [0, 0, 0]
    
    @colors =[[255,255,255],
              [100,100,100],
              [180,180,180],
              [120,120,120],
              [rand(255),0,0],
              [0,rand(255),0],
              [0,0,rand(255)]]
  end
  
  def generate(options = {})
    delete_old_files
    
    options = {
  		:fontsize => 25,
  		:padding => 20,
  		:color => '#000',
  		:background => '#fff',
  		:fontweight => 'bold',
  		:font => 'Courier',
  		:rotate => true,
  		:length => 5
  	}.update(options)

    @code = create_code(options[:length])

  	options[:fontweight] = case options[:fontweight]
  		when 'bold' then 700
  		else 400
  	end
	
  	text = Magick::Draw.new
  	text.pointsize = options[:fontsize]
  	text.font_weight = options[:fontweight]
  	text.fill = options[:color]
  	text.font = options[:font]
  	text.gravity = Magick::CenterGravity
	
  	#rotate text 5 degrees left or right
  	text.rotation = (rand(2)==1 ? 5 : -5) if options[:rotate]
	
  	metric = text.get_type_metrics(@code)

  	#add bg
  	canvas = Magick::ImageList.new
  	canvas << Magick::Image.new(metric.width+options[:padding], metric.height+options[:padding]){
  		self.background_color = options[:background]
  	}

  	#add text
  	canvas << Magick::Image.new(metric.width+options[:padding], metric.height+options[:padding]){
  		self.background_color = '#000F'
  	}.annotate(text, 0, 0, 0, 0, @code).wave(5, 50)

  	canvas << Magick::Image.new(metric.width+options[:padding], metric.height+options[:padding]){
  		p = Magick::Pixel.from_color(options[:background])
  		p.opacity = Magick::MaxRGB/1.4
  		self.background_color = p
  	}.add_noise(Magick::LaplacianNoise)

  	@image = canvas.flatten_images.blur_image(1)
  	write_to_file
  end

  protected
  def create_code(length)
    code = ""
    length.times do
      code << @key[rand(@key.length)]
    end
    return code
  end
  
  def write_to_file
    @filename = File.join( @@captcha_dir, rand(99999).to_s << ".png" )
		@image.write(@filename)
  end
  
  def draw_background
    color = @white
    pat = Cairo::SolidPattern.new(color)
    @image.rectangle(0,0, @image.width, @image.height)
    @image.set_source(pat)
    @image.fill
    
    num = 5
    num.times do |i|
      @image.set_source_rgb(random_color)
      start_x = rand(@image.width/num) + (@image.width/num * i)
      end_x = (@image.width / -2) + (2 * rand(@image.width))
      @image.move_to(start_x, 0)
      @image.line_to(end_x, @image.height)
      @image.stroke
    
      start_x = rand(@image.width/num) + (@image.width/num * i)
      middle_x = (@image.width / -2) + (2 * rand(@image.width))
      middle_y = @image.height + rand(@image.height) / 2
      end_x = (@image.width / -2) + (2 * rand(@image.width))
      @image.move_to(start_x, 0)
      @image.curve_to(start_x, 0, middle_x, middle_y, end_x, @image.height)
      @image.stroke
    end
  end
  
  def random_color
    @colors[rand(4)+3]
  end
  
  # Don't see a way to do this natively with cairo
  def draw_point(x, y, r, g, b)
    @image.move_to(x, y)
    @image.line_to(x + 1, y + 1)
    @image.set_source_rgb(r, g, b)
    @image.stroke
  end
  
  def delete_old_files
    Dir.open(@@captcha_dir) do |dir|
      dir.each do |file|
        unless file =~ /^\./
          full_path = File.join(@@captcha_dir, file)
          if Time.now.to_i - File.mtime( full_path ).to_i > 60
            File.delete( full_path )
          end
        end
      end
    end
  end
end
