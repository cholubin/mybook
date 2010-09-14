# encoding: utf-8
require 'rubygems'
require 'carrierwave/orm/datamapper'   
require 'dm-core'
require 'dm-validations'
require 'dm-pager'

$:.unshift File.dirname(__FILE__) + '/../lib'

class Book_structure
  
  # Class Configurations ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  include DataMapper::Resource
  attr_accessor :password
  
  # Attributes ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  property :id,                 Serial
  
  property :title, String
  property :cover, String
  property :inner_cover, String
  property :prologue, String
  property :index, String
  
  timestamps :at
    
end

DataMapper.auto_upgrade!