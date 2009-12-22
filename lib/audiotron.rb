#!/usr/bin/env ruby

#:: Title   : audiotron
#:: Author  : Mike Zazaian
#:: Updated : 2009-12-22


require 'rubygems'  # Require a list of ruby gems
require 'fileutils' # Require complex file utilities
require 'choice'    # Require the Choice option parser
require 'id3lib'    # Require the id3lib-ruby ID3 library


# Define the option parsing (via the Choice class)
Choice.options do
  separator ''
  option :range do
    short "-r"
    long "--range=RANGE"
    desc "Select scope of the audio files for operation."
    default "*.mp3"
  end
  
  option :verbose do
    short "-v"
    long "--verbose"
    desc "Choose whether to see application messages."
    default false
  end

  separator ''
  separator '  === id3 Options ==='

  option :artist do
    short "-a"
    long "--artist=ARTIST"
    desc "Set the id3v2 --artist tag for audio files in RANGE"
    default nil
  end
  
  option :album do
    short "-A"
    long "--album=ALBUM"
    desc "Set the id3v2 --album tag for audio files in RANGE"
    default nil
  end
  separator ''
end


module AudioTron
  module Version
    MAJOR = 0
    MINOR = 1
    MICRO = 8

    def self.print
      [MAJOR, MINOR, MICRO].join(".")
    end
  end

  class File
    attr_accessor :original, :new
    def initialize(original)
      # clear out tab returns or irregular characters from the original filename
      @original = original
      convert_original
    end
  
    def convert_original
      @new = @original.gsub(/^[^A-Za-z]+|[,]+/,"").downcase.gsub(/[\s]+/,"_")
    end
  
    def name_unchanged?
      @original == @new
    end
  
    def rename
      FileUtils.mv(@original, @new) unless name_unchanged?
    end
  end

  class Batch
    attr_accessor :file_names, :file_objects
    def initialize( range = Choice.choices[:range] )
      @file_names = Dir.glob(range)
      objectify 
    end

    # Take all of the audio filenames and convert them to AudioTron::File objects
    def objectify
      @file_objects = @file_names.collect do |fn|
        AudioTron::File.new(fn)
      end
    end

    # Rename all of the audio files in @file_objects with their sanitized names
    def rename_all
      @file_objects.each do |fo|
        fo.rename
      end
    end

    # Define the options that will be automatically taken from Choice.choices if
    # they're called as arguments when the script is run...
    ID3_OPTIONS = %w[ album artist ]
    # ..then iterate over all of the files and execute id3v2 at the command line to
    # tag the files
    def apply_id3_tags
      @file_objects.each do |fo|
        tag = ID3Lib::Tag.new(fo.new)
        ID3_OPTIONS.each do |o|
          next unless Choice.choices[o]
          tag.send("#{o}=", Choice.choices[o]) 
          puts "Set #{o} tag to \"#{Choice.choices[o]}\" for #{fo.new}" if Choice.choices[:verbose]
        end
        tag.update!
      end
    end
  end

  # TODO: Use this class to tag batches
  # TODO: Break these classes out into seperate files
  class Tagger
  end
end


# Create a new batch populated with all of the mp3 files in the current directory
batch = AudioTron::Batch.new
# Rename all of those files with a cleaner, lowercase-and-underscore convention
batch.rename_all
# Tag all of the audio files in the catch with the given info
batch.apply_id3_tags
