#!/usr/bin/env ruby
#--
# Copyright 2004, 2006 by Jim Weirich (jim@weirichhouse.org).
# All rights reserved.

# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#++

module PxBuilder
  if Object::const_defined?(:BasicObject)
    BlankSlate = ::BasicObject
  elsif !const_defined?(:BlankSlate)
    require 'blankslate'
    BlankSlate = ::BlankSlate
  end
end