require "sinatra"
require "json"
require "mongo"

require "cloud_foundry_environment"
require "mongodb_collection"

class ExampleApp < Sinatra::Application
  before do
    content_type "text/plain"

    unless mongo_service_bound_to_app?
      tell_user_how_to_bind
    end
  end

  post "/:collection" do
    # nothing
  end

  delete "/:collection" do
    collection_name = params[:collection]
    mongodb_collection.with_collection(collection_name) do |collection|
      collection.drop
    end
  end

  get "/:collection/:key" do
    collection_name = params[:collection]
    key = params[:key]
    mongodb_collection.with_collection(collection_name) do |collection|
      item = collection.find_one("key" => key)
      halt 404 if item.nil?
      item["value"]
    end
  end

  post "/:collection/:key/:value" do
    collection_name = params[:collection]
    key = params[:key]
    value = params[:value]

    mongodb_collection.with_collection(collection_name, false) do |collection|
      collection.update({'key' => key}, {'key' => key, 'value' => value}, upsert: true)
    end

    status 201
  end

  def tell_user_collection_not_found
    halt 404
  end

  def tell_user_how_to_bind
    bind_instructions = %{
      You must bind a MongoDB service instance to this application.

      You can run the following commands to create an instance and bind to it:

        $ cf create-service mongodb default mongodb-instance
        $ cf bind-service app-name mongodb-instance
    }
    halt 500, bind_instructions
  end

  private

  def mongodb_collection
    @mongodb_collection ||= MongodbCollection.new(self)
  end

  def cloud_foundry_environment
    @cloud_foundry_environment ||= CloudFoundryEnvironment.new
  end

  def mongo_service_bound_to_app?
    cloud_foundry_environment.mongo_uri
    true
  rescue CloudFoundryEnvironment::NoMongodbBoundError
    false
  end
end
