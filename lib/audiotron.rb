#!/usr/bin/env ruby

#:: Title   : audiotron
#:: Version : 0.1.1
#:: Author  : Mike Zazaian
#:: Updated : 2009-12-21


# Require complex file utilities
require 'fileutils'

class AudioFile
  attr_accessor :original, :new
  def initialize(original)
    # clear out tab returns or irregular characters from the original filename
    @original = original.chomp!
    convert_original
  end

  def convert_original
    @new = @original.gsub(/^[^A-Za-z]+|[,]+/,"").downcase.gsub(/[\s]+/,"_")
  end

  def name_unchanged?
    @original == @new
  end

  def move_original
    FileUtils.mv(@original, @new) unless name_unchanged?
  end
end

# get all of the audio files as an array
file_names = Dir.glob("*.mp3")

converted_files = file_names.collect do |file_name|
  AudioFile.new(file_name)
end

converted_files.each do |cf|
  cf.move_original
  %x[id3v2 --artist "Canadian Brass" #{cf.new}]
  %x[id3v2 --album "Christmas with the Canadian Brass" #{cf.new}]
end


