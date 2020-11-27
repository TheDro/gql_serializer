RSpec.describe GqlSerializer do
  it "has a version number" do
    expect(GqlSerializer::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(GqlSerializer.hello).to eq('hello')
  end

  describe 'parse_query' do
    it 'parses a simple example' do
      hasharray = GqlSerializer.parse_query('id')

      expect(hasharray).to eq(['id'])
    end

    it 'parses a complex example' do
      hasharray = GqlSerializer.parse_query('id person {name}')

      expect(hasharray).to eq(['id', {'person' => ['name']}])
    end

    it 'parses a nested example' do
      hasharray = GqlSerializer.parse_query('id person {name office {location}} email')

      expect(hasharray).to eq(['id', {'person' => ['name', {'office' => ['location']}]}, 'email'])
    end

    it 'parses aliases' do
      hasharray = GqlSerializer.parse_query('id email:address person:dude {name}')

      expect(hasharray).to eq(['id', 'email:address', {'person:dude' => ['name']}])
    end
  end
end
