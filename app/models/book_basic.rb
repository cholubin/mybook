# encoding: utf-8
require 'rubygems'
require 'carrierwave/orm/datamapper'   
require 'dm-core'
require 'dm-validations'
require 'dm-pager'

$:.unshift File.dirname(__FILE__) + '/../lib'

class Book_basic
  
  # Class Configurations ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  include DataMapper::Resource
  # Attributes ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  property :id,                 Serial
  property :title,              String
  property :cover,              String
  property :inner_cover,        String
  property :prologue_title,     String
  property :prologue_content,   Text  
  property :index_title,        String
  property :index_content,      Text  
  property :user_id,            Integer        
  timestamps :at

end

DataMapper.auto_upgrade!