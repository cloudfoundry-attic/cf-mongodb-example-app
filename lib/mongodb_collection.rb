class MongodbCollection
  def initialize(app)
    @app = app
  end

  def with_collection(collection_name, require_collection = true)
    with_database do |database|
      needs_collection = require_collection && !database_has_collection?(database, collection_name)
      app.tell_user_collection_not_found if needs_collection
      yield database.collection(collection_name)
    end
  end

  private

  def database_has_collection?(database, collection_name)
    database.collection_names.include?(collection_name)
  end

  def with_database
    begin
      client = Mongo::MongoClient.from_uri(mongo_uri)
      yield client.db
    rescue CloudFoundryEnvironment::NoMongodbBoundError, Mongo::ConnectionFailure
      app.tell_user_how_to_bind
    ensure
      client.close if client
    end
  end

  attr_reader :app

  def mongo_uri
    cloud_foundry_environment.mongo_uri
  end

  def cloud_foundry_environment
    @cloud_foundry_environment ||= CloudFoundryEnvironment.new
  end
end
