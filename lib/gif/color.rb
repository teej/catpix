module Catpix
  class Color
    attr_accessor :r, :g, :b

    def initialize(_red, _green, _blue)
      self.r = _red
      self.g = _green
      self.b = _blue
    end

    def to_hex
      [r, g, b].map{ |c| c.to_s(16) }.join
    end

    def to_s
      "R[#{r}] G[#{g}] B[#{b}] HEX[0x#{to_hex}]"
    end
  end
end


def Color(_r, _g, _b)
  Catpix::Color.new(_r, _g, _b)
end