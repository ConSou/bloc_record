require 'sqlite3'
require 'pg'

module Connection
  def connection
    if BlocRecord.database_service == "sqlite3"
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    elsif BlocRecord.database_service == "pg"
      @connection ||= PG.connect(dbname: BlocRecord.database_filename)
    end
  end
end
