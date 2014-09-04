class CloudFoundryEnvironment
  NoMongodbBoundError = Class.new(StandardError)

  def initialize(services = ENV.to_h.fetch("VCAP_SERVICES"))
    @services = JSON.parse(services)
  end

  def mongo_uri
    services.fetch("p-mongodb").first.fetch("credentials").fetch("uri")
  rescue KeyError
    raise NoMongodbBoundError
  end

  private

  attr_reader :services
end
