require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  
  def where(params)
    where_line = params.keys.map(&:to_s).map do |key|
      "#{key} = ?"
    end.join(" AND ")
    
    sql = <<-SQL
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL
    
    values = params.values
    results = DBConnection.execute(sql, *values)
    results.map { |item| self.new(item) }
  end
  
end

class SQLObject
  extend Searchable
end
