require 'sqlite3'
require 'bloc_record/schema'

module Persistence

  def self.include(base)
    base.extend(ClassMethods)
  end

  def save
    self.save! rescue false
  end

  def save!
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variables_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}" }.join(",")

    self.class.connection.execute <<-SQL
      UPDATE #{self.class.table}
       SET #{fields}
       WHERE id = #{self.id};
     SQL

     true
   end

   def self.included(base)
     base.extend(ClassMethods)
   end

   def update_attribute(attribute, value)
     self.class.update(self.id, {attribute => value})
   end

   def update_attributes(updates)
     self.class.update(self.id, updates)
   end

   def destroy
     self.class.destroy(self.id)
   end

  module ClassMethods

    def create(attrs)
      attrs = BlocRecord::Utility.converted_keys(attrs)
      attrs.delete "id"
      vals = attributes.map {|key| BlocRecord::Utility.sql_strings(attrs[key])}

      connection.execute <<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","});
      SQL

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end

    def update(id, updates)
      updates = BlocRecord::Utility.converted_keys(updates)
      updates.delete "id"
      updates_array = updates.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }

      where_clause = id.nil? ? ";" : "WHERE id = #{id};"

      connection.execute <<-SQL
        UPDATE #{table} SET #{updates_array * ","} #{where_clause}
      SQL
      true
    end

    def update_all(updates)
      update(nil, updates)
    end

    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id = #{id.first};"
      end

      connection.execute <<-SQL
        DELETE FROM #{table} #{where_clause}
      SQL
      true
    end

    def destroy_all(condition_args=nil)
      if condition_args.class == String
        conditions = condition_args
      elsif condition_args.class == Array
        condition = condition_args[0].gsub(/[?]/, condition_args[1])
      elsif condition_args.class == Hash && !conditions_args.empty?
        conditions_args = BlocRecord::Utility.convert_keys(conditions_args)
        conditions = conditions_args.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")

        connection.execute <<-SQL
          DELETE FROM #{table} WHERE #{conditions};
        SQL
      else
        connection.execute <<-SQL
          DELETE FROM #{table};
        SQL
        true
      end
    end

  end

end
