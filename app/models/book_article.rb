# encoding: utf-8
require 'rubygems'
require 'carrierwave/orm/datamapper'   
require 'dm-core'
require 'dm-validations'
require 'dm-pager'

$:.unshift File.dirname(__FILE__) + '/../lib'

class Book_article
  
  # Class Configurations ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  include DataMapper::Resource
  # Attributes ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  property :id,                 Serial
  
  property :book_basic_id,      Integer
  property :title,              String
  property :order,              Integer
  property :content,            Text
  property :self_level,         Integer
  property :upper_level,        Integer
  property :user_id,            Integer      
  timestamps :at
  
end

DataMapper.auto_upgrade!