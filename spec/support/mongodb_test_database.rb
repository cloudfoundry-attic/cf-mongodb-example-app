class MongodbTestDatabase
  attr_reader :name

  def initialize
    @name =  "test_" + SecureRandom.uuid
    @client = Mongo::MongoClient.new
  end

  def database
    @db ||= client.db(name)
  end

  def uri(args={})
    port = args.fetch(:port, 27017)
    "mongodb://localhost:#{port}/#{name}"
  end

  def insert_record(collection, document)
    database.collection(collection).insert(document)
  end

  def get_value(collection, key)
    database.collection(collection).find_one("key" => key).fetch('value')
  end

  def collection_names
    database.collection_names
  end

  def destroy
    client.drop_database(name)
  end

  private

  attr_reader :client
end
