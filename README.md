## Usage: reorder_id3.rb [-h] [-v] [-n] [topdir]

topdir - the top level directory from which to descend and re-order
  any mp3 files into disk/track order.
  
If 'topdir' is omitted use the current directory as the top level
directory.

### Requires
This script uses the mp3info and ogginfo gems.

## Background
  This program came about because a number of devices which play mp3s
  from an SD card would just play them in native file creation order.
  This was often not the correct order for albums, so this program
  ensures that the native file created order matches the disk/track
  order of the mp3 files in each directory based on the information
  in the ID3 tag.
