module BlocRecord

  def self.connect_to(filename, database_service)
    @database_filename = filename
    @database_service = database_service.to_s
  end

  def self.database_filename
    @database_filename
  end

  def self.database_service
    @database_service
  end

end
