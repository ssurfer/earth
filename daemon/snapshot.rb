# Copyright (C) 2006 Rising Sun Pictures and Matthew Landauer.
# All Rights Reserved.
#  
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# $Id$

class Snapshot < FileMonitor
  attr_reader :directory, :subdirectories

  def initialize(observer, directory)
    super(observer)
    @directory = directory
    @subdirectories = Hash.new

    @stats = Hash.new
    @directory_stat = nil
    @subdirectory_names = []
  end
  
  def update_contents
    if File.exist?(@directory.path)
      new_stat = File.lstat(@directory.path)
      if new_stat != @directory_stat
        @directory_stat = new_stat
        # Update contents of directory if readable
        if @directory_stat.readable?
          entries = Dir.entries(@directory.path)
          # Ignore all files and directories starting with '.'
          entries.delete_if {|x| x[0,1] == "."}
          
          # TODO: Optimisation - do lstat on all directory entries and use that to determine what is a file
          filenames, @subdirectory_names = entries.partition{|f| File.file?(File.join(@directory.path, f))}
          @stats.clear
          filenames.each {|f| @stats[f] = File.lstat(File.join(@directory.path, f))}
        end
      end
    else
      # Directory has been removed
      @stats.clear
      @directory_stat = nil
      @subdirectory_names.clear
    end
  end
  
  def update
    old_subdirectory_names = @subdirectory_names.clone
    old_stats = @stats.clone
    old_file_names = old_stats.keys

    update_contents

    (old_file_names & file_names).each do |x|
      if old_stats[x] != @stats[x]
        file_changed(@directory, x, @stats[x])
      end
    end
    (@subdirectory_names - old_subdirectory_names).each do |d|
      @subdirectories[d] = directory_added(File.join(directory.path, d))
    end
    (file_names - old_file_names).each {|x| file_added(@directory, x, @stats[x])}
    (old_file_names - file_names).each {|x| file_removed(@directory, x)}
    (old_subdirectory_names - @subdirectory_names).each do |d|
      directory_removed(@subdirectories[d])
      @subdirectories.delete(d)
    end
  end
  
  def file_names
    @stats.keys
  end
end
