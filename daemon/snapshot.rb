# Copyright (C) 2006 Rising Sun Pictures and Matthew Landauer.
# All Rights Reserved.
#  
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# $Id$

class Snapshot
  def initialize(directory, observer)
    @observer = observer
    @directory = directory 
  end
  
  def update
    # TODO: remove exist? call as it is an extra filesystem access
    if File.exist?(@directory.path)
      new_directory_stat = File.lstat(@directory.path)
    else
      new_directory_stat = nil
    end
    
    # If directory hasn't changed then return
    if new_directory_stat == @directory.stat
      return
    end

    file_names, subdirectory_names, stats = [], [], Hash.new
    if new_directory_stat && new_directory_stat.readable? && new_directory_stat.executable?
      file_names, subdirectory_names, stats = contents(@directory)
    end

    added_directory_names = subdirectory_names - @directory.children.map{|x| x.name}
    added_directory_names.each do |name|
      directory = @directory.child_create(:name => name)
      @observer.directory_added(directory) unless @observer.nil?
    end

    # By adding and removing files on the association, the cache of the association will be kept up to date
    added_file_names = file_names - @directory.file_info.map{|x| x.name}
    added_file_names.each do |name|
      @directory.file_info.create(:name => name, :stat => stats[name])
    end

    @directory.file_info.each do |file|
      # If the file still exists
      if file_names.include?(file.name)
        # If the file has changed
        if file.stat != stats[file.name]
          file.stat = stats[file.name]
          file.save
        end
      # If the file has been deleted
      else
        @directory.file_info.delete(file)
      end
    end
    
    @directory.children.each do |dir|
      # If the directory has been deleted
      if !subdirectory_names.include?(dir.name)
        @observer.directory_removed(dir) unless @observer.nil?
        @directory.child_delete(dir)
      end
    end
    
    # Update the directory stat information at the end
    if File.exist?(@directory.path)
      @directory.reload
      @directory.stat = new_directory_stat
      @directory.save
    end
  end

private

  def contents(directory)
    entries = Dir.entries(directory.path)
    # Ignore all files and directories starting with '.'
    entries.delete_if {|x| x[0,1] == "."}
    
    # Contains the stat information for both files and directories
    stats = Hash.new
    entries.each {|x| stats[x] = File.lstat(File.join(directory.path, x))}
  
    # Seperately test for whether it's a file or a directory because it could
    # be something like a symbolic link (which we shouldn't follow)
    file_names = entries.select{|x| stats[x].file?}
    subdirectory_names = entries.select{|x| stats[x].directory?}
    
    return file_names, subdirectory_names, stats
  end
end
