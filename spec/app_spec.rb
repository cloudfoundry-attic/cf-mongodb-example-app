require "json"
require "mongo"
require "rack/test"
require "securerandom"

require 'support/help_the_user'
require 'support/mongodb_test_database'

require "app"

describe "MongoDB Example Application" do
  include Rack::Test::Methods

  def app
    ExampleApp
  end

  let(:database) { MongodbTestDatabase.new }

  def services_json_for_uri(uri)
    JSON.generate({
      "p-mongodb" => [
        {
          "credentials" => {
              "uri" => uri
          }
        }
      ]
    })
  end

  before do
    ENV['VCAP_SERVICES'] = services_json_for_uri(database.uri)
  end

  after do
    database.destroy
  end

  def with_no_mongo_bound
    ENV['VCAP_SERVICES'] = "{}"
  end

  describe 'GET /' do

    context 'when the mongo service is not bound to the app' do

      before do
        with_no_mongo_bound
      end

      it 'returns instructions on how to bind' do
        get '/'
        expect(last_response).to help_the_user
      end
    end
  end

  describe "POST /:collection" do
    it "does nothing but returns 200 to conform to the example application interface" do
      post "/fruit"

      expect(last_response.status).to eq(200)
    end
  end

  describe "DELETE /:collection" do
    it "removes the collection from the database" do
      database.insert_record("fruit", {"key" => "banana", "value" => "potassium"})


      delete "/fruit"

      expect(last_response.status).to eq(200)
      expect(database.collection_names).to_not include("fruit")
    end

    it "returns 500 when no Mongo URI is configured" do
      with_no_mongo_bound

      delete "/fruit"

      expect(last_response).to help_the_user
    end

    it "returns a 404 if the collection is not found" do
      delete "/fruit"

      expect(last_response.status).to eq(404)
    end
  end

  describe "GET /:collection/:key" do
    context 'when the fruit collection has been created' do

      before do
        database.insert_record("fruit", {"key" => key, "value" => "potassium"})
      end

      context "when the key has already been set" do

        let(:key) { 'banana' }

        it "retrieves it from the database" do
          get "/fruit/banana"

          expect(last_response.status).to eq(200)
          expect(last_response.body).to eq("potassium")
        end
      end

      context "when the key has not already been set" do

        let(:key) { 'payaya' }

        it "returns 404 when asked for a document which does not exist" do
          get "/fruit/banana"

          expect(last_response.status).to eq(404)
        end
      end
    end

    context "when the collection doesn't exist (same as case above because mongodb creates collections lazily)" do
      it "returns 404 when asked for a collection which does not exist" do
        get "/fruit/banana"

        expect(last_response.status).to eq(404)
      end
    end

    context "when the mongodb service is not bound to the app" do
      before do
        with_no_mongo_bound
      end

      it "returns 500 when the service is not bound" do
        get "/fruit/banana"

        expect(last_response).to help_the_user
      end
    end

    context "when the app cannot connect to mongodb" do
      before do
        ENV['VCAP_SERVICES'] = services_json_for_uri(database.uri(port: 9999))
      end

      it "returns 500 when it cannot connect to Mongo" do
        get "/fruit/banana"

        expect(last_response.status).to eq(500)
      end
    end
  end

  describe 'POST /:collection/:key/:value' do

    it 'returns 201' do
      post "/fruit/papaya/newvalue"

      expect(last_response.status).to eq(201)
    end

    it 'returns empty body' do
      post "/fruit/papaya/newvalue"

      expect(last_response.body).to be_empty
    end

    context 'collection already exists' do

      before do
        database.insert_record('fruit', { "key" => key, "value" => 'green' })
      end

      context 'value already exists for this key' do

        let(:key) { 'apple' }

        it 'sets a new value for the key in the collection' do
          post "/fruit/#{key}/newvalue"

          value = database.get_value('fruit', key)
          expect(value).to eq('newvalue')
        end
      end

      context 'value does not exist for this key' do

        let(:key) { 'pear' }

        it 'sets a new value for the key in the collection' do
          post "/fruit/apple/newvalue"

          value = database.get_value('fruit', 'apple')
          expect(value).to eq('newvalue')
        end
      end
    end

    context 'collection does not already exist' do

      it 'sets a new value for the key in the collection' do
        post "/fruit/papaya/newvalue"

        value = database.get_value('fruit', 'papaya')
        expect(value).to eq('newvalue')
      end
    end
  end
end
