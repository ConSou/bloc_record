require 'sqlite3'

module Selection

  def find(*ids)

    if ids.length == 1
      find_one(ids.first)
    else
      rows.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table} WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(row)
    end
  end

  def find_one(id)
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table} WHERE id = #{id};
    SQL

    init_object_from_row(row)
  end

  def find_by(attribute, value)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    rows_to_array(rows)
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

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.converted_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table} WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    if args.count > 1
      order = []
      args.each do |item|
        case item
          when String, Symbol
            order << item
          when Hash
            item.map {|k, v| order.push("#{k} #{v.upcase}")}
        end
      end
    order = order.join(",")
    else
      order = order.to_s
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table} ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map {|arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins};
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        join_array = args.first.flatten
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} INNER JOIN #{join_array[0]} ON #{join_array[0]}.#{table}_id = #{table}.id INNER JOIN #{join_array[1]} ON #{join_array[1]}.#{join_array[0]}_id = #{join_array[0]}.id;
        SQL
      end
    end
    rows_to_array(rows)
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
