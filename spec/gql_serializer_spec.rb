require 'active_record'

RSpec.describe GqlSerializer do
  it "has a version number" do
    expect(GqlSerializer::VERSION).not_to be nil
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


  describe 'as_gql' do
    before(:all) do
      ActiveRecord::Base.establish_connection(
        adapter: 'sqlite3',
        database: 'test.db'
      )


      ActiveRecord::Migration.verbose = false
      ActiveRecord::Migration.create_table(:test_users) do |t|
        t.string :name
        t.string :email
      end
      ActiveRecord::Migration.create_table(:test_orders) do |t|
        t.bigint :test_user_id
        t.float :total
      end
      ActiveRecord::Migration.create_table(:test_items) do |t|
        t.bigint :test_order_id
        t.float :price
      end
    end


    class TestUser < ActiveRecord::Base
      has_many :test_orders
      def encoded_id
        "TestUser-#{id}"
      end
    end

    class TestOrder < ActiveRecord::Base
      belongs_to :test_user
      has_many :test_items
    end

    class TestItem < ActiveRecord::Base
      belongs_to :test_order
    end

    after(:all) do
      ActiveRecord::Migration.drop_table(:test_users)
      ActiveRecord::Migration.drop_table(:test_orders)
      ActiveRecord::Migration.drop_table(:test_items)
    end

    it 'serializes a model' do
      user = TestUser.create(name: 'John', email: 'john@test.com')

      expect(user.as_gql('name')).to eq({'name' => 'John'})
      expect(user.as_gql).to eq({'id' => user.id, 'name' => 'John', 'email' => 'john@test.com'})
    end

    it 'serializes an array of models' do
      users = [
        TestUser.create(name: 'John', email: 'john@test.com'),
        TestUser.create(name: 'Jane', email: 'jane@test.com')]

      expect(users.as_gql).to eq([
        {'id' => users[0].id, 'name' => 'John', 'email' => 'john@test.com'},
        {'id' => users[1].id, 'name' => 'Jane', 'email' => 'jane@test.com'}
      ])
    end

    it 'serializes relations' do
      user = TestUser.create(name: 'John', email: 'john@test.com')
      orders = [TestOrder.create(total: 5.00, test_user: user), TestOrder.create(total: 10.00, test_user: user)]

      expect(orders[0].as_gql).to eq({'id' => orders[0].id, 'test_user_id' => user.id, 'total' => 5.00})
      expect(user.as_gql('test_orders')).to eq({
        'id' => user.id, 'name' => 'John', 'email' => 'john@test.com',
        'test_orders' => orders.as_gql
      })
    end

    it 'serializes nested relations' do
      user = TestUser.create(name: 'John', email: 'john@test.com')
      orders = [TestOrder.create(total: 5.00, test_user: user), TestOrder.create(total: 10.00, test_user: user)]
      items_1 = [
        TestItem.create(test_order: orders[0], price: 2.00),
        TestItem.create(test_order: orders[0], price: 3.00)
      ]
      items_2 = [
        TestItem.create(test_order: orders[1], price: 10.00)
      ]

      expect(items_1[0].as_gql).to eq({
        'id' => items_1[0].id, 'price' => 2.00, 'test_order_id' => orders[0].id
      })
      expect(orders[0].as_gql('test_items')).to eq({
        'id' => orders[0].id, 'test_user_id' => user.id, 'total' => 5.00, 'test_items' => items_1.as_gql
      })
      expect(user.as_gql('test_orders {test_items}')).to eq({
        'id' => user.id, 'name' => 'John', 'email' => 'john@test.com',
        'test_orders' => [orders[0].as_gql('test_items'), orders[1].as_gql('test_items')]
      })
    end

    it 'uses aliases' do
      user = TestUser.create(name: 'John', email: 'john@test.com')
      orders = [TestOrder.create(total: 5.00, test_user: user), TestOrder.create(total: 10.00, test_user: user)]

      expect(user.as_gql('id:identity name email:address')).to eq({
        'identity' => user.id, 'name' => user.name, 'address' => user.email
      })

      expect(user.as_gql('email:address test_orders:orders {total:cost}')).to eq({
        'address' => user.email,
        'orders' => [{'cost' => orders[0].total}, {'cost' => orders[1].total}]
      })
    end

    it 'supports methods' do
      user = TestUser.create(name: 'John', email: 'john@test.com')

      expect(user.as_gql('encoded_id')).to eq({'encoded_id' => "TestUser-#{user.id}"})
      expect(user.as_gql('encoded_id:id')).to eq({'id' => "TestUser-#{user.id}"})
    end

    describe 'case conversions' do
      class CaseUser < TestUser
        def snake_case
          'snake'
        end

        def camelCase
          'camel'
        end
      end

      it 'converts keys to camel case' do
        user = CaseUser.create(name: 'John')

        expect(user.as_gql('snake_case camelCase',
          {case: GqlSerializer::Configuration::CAMEL_CASE}))
          .to eq({'snakeCase' => 'snake', 'camelCase' => 'camel'})
      end

      it 'converts keys to snake case' do
        user = CaseUser.create(name: 'John')

        expect(user.as_gql('snake_case camelCase',
          {case: GqlSerializer::Configuration::SNAKE_CASE}))
        .to eq({'snake_case' => 'snake', 'camel_case' => 'camel'})
      end

      it 'uses the configured case by default' do
        binding.pry
      end
    end
  end

end
