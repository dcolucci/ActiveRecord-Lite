require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]
    
    source_options = through_options.model_class.assoc_options[source_name]
    
    define_method(name) do
      
      source_fk = source_options.foreign_key
      through_pk_val = send(through_options.primary_key)
      
      through_pk = through_options.primary_key
      source_pk = source_options.primary_key      
      
      sql = <<-SQL
        SELECT
          source.*
        FROM
          #{source_options.table_name} source
        INNER JOIN
          #{through_options.table_name} through
        ON
          source.#{source_pk} = through.#{source_fk}
        WHERE
          through.#{through_pk} = ?
      SQL
      
      result = DBConnection.execute(sql, through_pk_val)
        
      source_options.model_class.parse_all(result).first
      
    end
    
    nil
  end
end
