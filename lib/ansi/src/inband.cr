module Ansi
  # InBandResize encodes an in-band terminal resize event sequence.
  #
  #	CSI 48 ; height_cells ; widht_cells ; height_pixels ; width_pixels t
  #
  # See https://gist.github.com/rockorager/e695fb2924d36b2bcf1fff4a3704bd83
  def self.in_band_resize(height_cells : Int32, width_cells : Int32, height_pixels : Int32, width_pixels : Int32) : String
    height_cells = 0 if height_cells < 0
    width_cells = 0 if width_cells < 0
    height_pixels = 0 if height_pixels < 0
    width_pixels = 0 if width_pixels < 0
    "\e[48;#{height_cells};#{width_cells};#{height_pixels};#{width_pixels}t"
  end
end
