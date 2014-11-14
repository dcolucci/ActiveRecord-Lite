require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  
  def self.columns
    sql = "select * from #{self.table_name}"
    results = DBConnection.execute2(sql)
    
    results.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |method_name|
      define_method(method_name) do
        self.attributes[method_name]
      end
    end
    
    columns.each do |method_name|
      define_method("#{method_name}=") do |arg|
        self.attributes[method_name] = arg
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    sql = "select * from #{self.table_name}"
    parse_all(DBConnection.execute(sql))
  end

  def self.parse_all(results)
    results.map do |hsh|
      self.new(hsh)
    end
  end

  def self.find(id)
    sql = "select * from #{self.table_name} where id = #{id}"
    self.new(DBConnection.execute(sql).first)
  end

  def initialize(params = {})
    params.each do |attribute, value|
      unless self.class.columns.include?(attribute.to_sym)
        raise "unknown attribute '#{attribute}'"
      end
      
      send("#{attribute}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |col| send(col) }
  end

  def insert
    cols = self.class.columns
    col_names = cols.join(",")
    question_marks = Array.new(cols.length) { "?" }.join(",")
    
    sql = <<-SQL
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    
    DBConnection.execute(sql, *attribute_values)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.columns.map do |col|
      "#{col} = ?"
    end.join(",")

    sql = <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
    
    DBConnection.execute(sql, *attribute_values, self.id)
  end

  def save
    unless self.id
      self.insert
      return
    end
    
    self.update
  end
end
