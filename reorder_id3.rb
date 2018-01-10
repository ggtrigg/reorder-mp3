#! /usr/bin/env ruby

require 'find'
require 'pathname'
require 'fileutils'
require 'mp3info'
require 'ogginfo'

TMPDIRNAME = Pathname.new('.temp_mp3_dir')

hlist = {}

class Song
  attr_reader :tracknum, :disknum, :dirname, :filename

  def initialize(path)
    @dirname, @filename = File.split(path)
    @m3i = Mp3Info.new(path)
    @tracknum = @m3i.hastag? ? @m3i.tag.tracknum.to_i : 0
    @disknum = @m3i.hastag2? ? @m3i.tag2.TPOS.to_i : 0
  end

  def to_s
    @m3i.hastag? ? "#{@tracknum} - #{@m3i.tag.title}" : @filename
  end

  # If there are ID3 tags present, sort by disk number (ID3v2 only) then
  # by track number, otherwise sort by filename.
  def <=>(other)
    if @disknum != other.disknum
      @disknum <=> other.disknum
    elsif @tracknum != other.tracknum
      @tracknum <=> other.tracknum
    else
      @filename <=> other.filename
    end
  end
end

# Simple arg parsing for displaying usage - can convert to a fuller
# featured arg parsing later if needed.
if ($*.count > 0) && ($*[0] == '-h') then
	printf("Usage: %s [-h] [topdir]\n", File.basename($0));
	print <<EOD

topdir - the top level directory from which to descend and re-order
  any mp3 files into disk/track order.
  
If 'topdir' is omitted use the current directory as the top level
directory.

Background
  This program came about because a number of devices which play mp3s
  from an SD card would just play them in native file creation order.
  This was often not the correct order for albums, so this program
  ensures that the native file created order matches the disk/track
  order of the mp3 files in each directory based on the information
  in the ID3 tag.
EOD
	exit 0
end

# If a directory is specified then use that as the root otherwise start
# at the current directory.
root_dir = ($*.count > 0) ? $*.shift : '.'

unless File.directory? root_dir then
	warn root_dir + ' is not a directory.'
	exit -2
end

# Find all mp3 files under the specified directory and build a hash of
# each directory and associated list of songs.
begin
	Find.find(root_dir) do |path|
	  if (path =~ /\.mp3$/) && (File.file?(path)) && (File.size(path) > 0)
		sng = Song.new(path)
		hlist.key?(sng.dirname) ? hlist[sng.dirname] << sng : hlist[sng.dirname] = [sng]
	  end
	end
rescue => exception
	warn exception.message
	exit -1
end

# hlist.each {|key, val| print "Dir #{key}: [#{val.sort!.join(', ')}]\n"}

hlist.each do |dir, files|
  Dir.chdir(dir) do
    # make a temporary directory, move all the files there in the
    # correct (sorted) order, then move them all back here
    # finally remove the temporary directory.
    Dir.mkdir(TMPDIRNAME)
    files.sort!.each { |song| FileUtils.mv(song.filename, TMPDIRNAME)}
    files.each { |song| FileUtils.mv(TMPDIRNAME + song.filename, '.')}
    Dir.rmdir(TMPDIRNAME)
  end
end
