require 'sqlite3'

module Selection

  def find(*ids)

    if ids.length == 1
      find_one(ids.first)
    elsif ids.all? {|i| i.is_a?(Integer) && i >= 0 }
      rows.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table} WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(row)
    else
      raise TypeError, "Arguments must all be of type integer"
    end
  end

  def find_one(id)
    if id.is_a?(Integer) && id >= 0
      row = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table} WHERE id = #{id};
      SQL
      init_object_from_row(row)
    else
      raise TypeError, "Argument must be of type integer"
  end

  def find_by(attribute, value)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    rows_to_array(rows)
  end

  def find_each(start: nil, batch_size: nil)
    if start.nil?
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table};
      SQL
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table} ORDER BY id LIMIT #{batch_size} OFFSET #{start};
      SQL
    end
    yield rows_to_array(rows)
  end

  def find_in_batches(options={})
    start = options[:start]
    batch_size = options[:batch_size]

    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table} ORDER BY id LIMIT #{batch_size} OFFSET #{start};
    SQL
    yield rows
  end

  def take_one
    row = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def take(num=1)
    if num > 1
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random() LIMIT #{num}
      SQL
      rows_to_array(rows)
    else
      take_one
    end
  end

  def first
    row = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table} ORDER BY id ASC LIMIT 1;
    SQL
    init_object_from_row(row)
  end

  def last
    row = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table} ORDER BY id DESC LIMIT 1;
    SQL
    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def method_missing(m, *args)
    if m.to_s.include?("find_by_")
      attr = m.to_s.gsub!(/find_by_/, "")
      find_by(attr, args[0])
    else
      raise NoMethodError, "NoMethod \"#{m}\""
    end
  end

  private

  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end

end
