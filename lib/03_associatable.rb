require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.class_name.constantize.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      foreign_key: "#{name}_id".underscore.to_sym,
      primary_key: "id".to_sym,
      class_name: name.to_s.camelcase
    }
    
    options = defaults.merge(options)
    
    @name = name
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      foreign_key: "#{self_class_name}_id".underscore.to_sym,
      primary_key: "id".to_sym,
      class_name: "#{name}".singularize.camelcase
    }
    
    options = defaults.merge(options)
    
    @name = name
    @self_class_name = self_class_name
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]
    @class_name = options[:class_name]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    
    define_method(name) do
      fk = send(options.foreign_key)
      target_model_class = options.model_class
      target_model_class.where(options.primary_key => fk).first
    end
    
    self.assoc_options[name] = options
    
    nil
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    
    define_method(name) do
      fk = options.foreign_key
      target_model_class = options.model_class
      target_model_class.where(fk => send(options.primary_key))
    end
    
    nil
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
