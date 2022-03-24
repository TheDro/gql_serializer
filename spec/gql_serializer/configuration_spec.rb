

RSpec.describe GqlSerializer::Configuration do
  describe 'case' do
    after do
      GqlSerializer.configuration.reset
    end

    it 'supports none, snake case and camel case' do
      GqlSerializer.configure do |config|
        config.case = GqlSerializer::Configuration::NONE_CASE
        config.case = GqlSerializer::Configuration::SNAKE_CASE
        config.case = GqlSerializer::Configuration::CAMEL_CASE
      end

      expect(GqlSerializer.configuration.case).to eq(:camel)
    end

    it 'raises an error for unsupported cases' do
      GqlSerializer.configure do |config|
        config.case = :unsupported
      end

      raise "error was not raised"
    rescue => e
      expect(e.message).to include("not supported")
    end

    it 'allows preload to be enabled' do
      GqlSerializer.configure do |config|
        config.preload = true
      end

      expect(GqlSerializer.configuration.preload).to eq(true)
    end
  end
end