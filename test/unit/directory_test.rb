require File.dirname(__FILE__) + '/../test_helper'

class DirectoryTest < Test::Unit::TestCase
  fixtures :directories, :file_info, :servers

  def test_server
    assert_equal(servers(:first), directories(:foo_bar_twiddle).server)
  end
  
  def test_path
    assert_equal("/foo", directories(:foo).path)
    assert_equal("/foo/bar", directories(:foo_bar).path)
    assert_equal("/foo/bar/twiddle", directories(:foo_bar_twiddle).path)
  end
  
  def test_path_on_create
    dir = Server.this_server.directories.create(:name => "another", :parent => directories(:foo_bar))
    assert_equal("/foo/bar/another", dir.path)
    dir = Server.this_server.directories.create(:name => "/a/root/directory")
    assert_equal("/a/root/directory", dir.path)
  end
  
  # Tests an alternative interface to "move_to_child_of"
  def test_set_parent 
    assert_equal(2, directories(:foo_bar).lft)
    assert_equal(5, directories(:foo_bar).rgt)
    dir = Server.this_server.directories.create(:name => "another")
    dir.parent = directories(:foo_bar)
    dir.save
    assert_equal(directories(:foo_bar).id, dir.parent_id)
    assert_equal("/foo/bar/another", dir.path)
    assert_equal(3, dir.lft)
    assert_equal(4, dir.rgt)
    
    directories(:foo_bar).reload
    assert_equal(2, directories(:foo_bar).lft)
    assert_equal(7, directories(:foo_bar).rgt)
  end
  
  def test_set_parent_on_create
    dir = Server.this_server.directories.create(:name => "another", :parent => directories(:foo_bar))
    assert_equal(directories(:foo_bar).id, dir.parent_id)
    assert_equal(3, dir.lft)
    assert_equal(4, dir.rgt)
    
    directories(:foo_bar).reload
    assert_equal(2, directories(:foo_bar).lft)
    assert_equal(7, directories(:foo_bar).rgt)    
  end
  
  def test_name
    assert_equal("/foo", directories(:foo).name)
    assert_equal("bar", directories(:foo_bar).name)
    assert_equal("twiddle", directories(:foo_bar_twiddle).name)
  end
  
  def test_stat
    # Getting a File::Stat from a "random" file
    stat = File.lstat(File.dirname(__FILE__) + '/../test_helper.rb')
    directories(:foo).stat = stat
    assert_equal(stat.mtime, directories(:foo).modified)
    # And we should be able to read back as a stat object
    assert_equal(stat.mtime, directories(:foo).stat.mtime)
    # And we should be able to directly compare the stats even though they are different kinds of object
    assert_kind_of(File::Stat, stat)
    assert_kind_of(Directory::Stat, directories(:foo).stat)
    assert_equal(stat, directories(:foo).stat)
    assert_equal(directories(:foo).stat, stat)
  end
  
  def test_size
    assert_equal(file_info(:file1).size + file_info(:file2).size, directories(:foo).size)
    assert_equal(file_info(:file3).size + file_info(:file4).size, directories(:foo_bar).size)
    assert_equal(0, directories(:foo_bar_twiddle).size)
  end
  
  def test_recursive_size
    assert_equal(file_info(:file1).size + file_info(:file2).size + file_info(:file3).size + file_info(:file4).size,
      directories(:foo).recursive_size)
    assert_equal(file_info(:file3).size + file_info(:file4).size,
      directories(:foo_bar).recursive_size)
  end
  
  # Doing this to double-check my understanding of caching with associations in ActiveRecord
  # assert_no_queries was taken from ActiveRecord tests
  def test_association_caching
    file1 = file_info(:file1)
    file2 = file_info(:file2)
    foo = directories(:foo)
    
    assert_equal([file1, file2], foo.file_info)
    assert_no_queries {assert_equal([file1, file2], foo.file_info)}
    # Test that creating on an association like this means that the cached association gets updated too
    file3 = foo.file_info.create(:name => "c", :size => 3)
    assert_no_queries {assert_equal([file1, file2, file3], foo.file_info)}
    foo.file_info.delete(file2)
    assert_no_queries {assert_equal([file1, file3], foo.file_info)}
  end
  
  #TODO: Write test_child_create

  def test_children
    foo = directories(:foo)
    foo_bar = directories(:foo_bar)
    
    assert_equal([foo_bar], foo.children)
    assert_no_queries{assert_equal([foo_bar], foo.children)}
    
    foo_fiddle = foo.child_create(:name => "fiddle")
    assert_no_queries{assert_equal([foo_fiddle, foo_bar], foo.children)}
    # Force a reload of children and check that the values are correct too
    assert_queries(1){assert_equal([foo_fiddle, foo_bar], foo.children(true))}
    foo.child_delete(foo_bar)
    assert_no_queries{assert_equal([foo_fiddle], foo.children)}
    assert_queries(1){assert_equal([foo_fiddle], foo.children(true))}
  end
  
end
