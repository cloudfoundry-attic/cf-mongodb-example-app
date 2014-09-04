RSpec::Matchers.define :help_the_user do
  match do |response|
    expect(response.status).to eq(500)
    expect(response.body).to include("You must bind a MongoDB service instance to this application.")
  end

  def include(thing)
    # without this Kernel#include is called
    RSpec::Matchers::BuiltIn::Include.new(thing)
  end
end
