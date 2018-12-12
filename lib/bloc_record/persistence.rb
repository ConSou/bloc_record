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
     if updates.class != Hash
       raise TypeError, "arguments must be a hash"
     end
     self.class.update(self.id, updates)
   end

   def method_missing(m, *args)
     if m.to_s.include?("update_")
       attr = m.to_s.gsub!(/update_/, "")
       self.update_attribute(attr, args[0])
     else
       raise NoMethodError, "NoMethod \"#{m}\""
     end
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

    def update(ids, updates)
      if ids.nil? || ids.class == Integer || ids.class == Array
        if ids.class == Array && !ids.all? {|i| i.is_a?(Integer) }
          raise TypeError, "Argument must be an array or integers or a single integer"
        end
        updates = BlocRecord::Utility.converted_keys(updates)
        updates.delete "id"
        updates_array = updates.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }

        if ids.class == Fixnum
          where_clause = "WHERE id = #{ids};"
        elsif ids.class == Array
          where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
        else
          where_clause = ";"
        end

        connection.execute <<-SQL
          UPDATE #{table} SET #{updates_array * ","} #{where_clause}
        SQL
        true
      end
    end

    def update_all(updates)
      update(nil, updates)
    end

  end

end
