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

      ActiveRecord::Migration.drop_table(:test_users, if_exists: true)
      ActiveRecord::Migration.drop_table(:test_orders, if_exists: true)
      ActiveRecord::Migration.drop_table(:test_items, if_exists: true)

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


    it 'serializes a model' do
      user = TestUser.create(name: 'John', email: 'john@test.com')

      expect(user.as_gql('name')).to eq({'name' => 'John'})
      expect(user.as_gql).to eq({'id' => user.id, 'name' => 'John', 'email' => 'john@test.com'})
    end

    it 'serializes an array of models' do
      users = [
        TestUser.create(name: 'John', email: 'john@test.com'),
        TestUser.create(name: 'Jane', email: 'jane@test.com')
      ]

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

    it 'serializes hashes' do
      book = {
        id: 1, "book_name" => "Ruby 101", meta_data: {pages: 120, author: 'John'},
        chapters: [{id: 11, chapter_name: "Getting started"}, {id: 12, chapter_name: "Advanced"}]
      }

      expect(book[:chapters].as_gql).to eq([
        {'id' => 11, 'chapter_name' => 'Getting started'},
        {'id' => 12, 'chapter_name' => 'Advanced'}
      ])
      expect(book[:meta_data].as_gql).to eq({
        'pages' => 120, 'author' => 'John'
      })
      expect(book.as_gql).to eq({'id' => 1, 'book_name' => 'Ruby 101',
        'chapters' => book[:chapters].as_gql, 'meta_data' => book[:meta_data].as_gql
      })
      expect(book[:chapters].as_gql('id')).to eq([
        {'id' => 11}, {'id' => 12}
      ])
      expect(book.as_gql('id chapters {chapter_name}')).to eq({
        'id' => 1, 'chapters' => book[:chapters].as_gql('chapter_name')
      })
      expect([book].as_gql('id meta_data')).to eq([book.as_gql('id meta_data')])
    end

    it 'serializes objects in hashes' do
      hash = {message: 'hello_world'}

      expect(hash.as_gql('message{camelcase titlecase:title to_s:value')).to eq({
        'message' => {'camelcase' => 'HelloWorld', 'title' => 'Hello World', 'value' => 'hello_world'}
      })
      expect(hash.as_gql('message{camelcase{first}}')).to eq({
        'message' => {'camelcase' => {'first' => 'H'}}
      })
    end

    it 'serializes a mix of hashes and models' do
      author = TestUser.create(name: 'John', email: 'john@test.com')
      book = {id: 1, author: author}

      expect(book.as_gql('id author {name}')).to eq({
        'id' => 1, 'author' => {'name' => 'John'}
      })
      expect(author.as_gql('id as_json')).to eq({
        'id' => author.id, 'as_json' => author.as_json.as_gql
      })
      expect(author.as_gql('id as_json {name}')).to eq({
        'id' => author.id, 'as_json' => {'name' => 'John'}
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

    describe 'regular objects' do
      class ObjectUser
        attr_accessor :first_name, :last_name
        def initialize(first_name, last_name)
          @first_name = first_name
          @last_name = last_name
        end

        def full_name
          "#{first_name} #{last_name}"
        end
      end
      ObjectUser.include GqlSerializer::Object

      it 'serializes objects' do
        user = ObjectUser.new('John', 'Snow')

        expect(user.as_gql('first_name full_name:wholeName')).to eq({
          'first_name' => 'John', 'wholeName' => 'John Snow'
        })
        expect(user.as_gql('first_name last_name { first }')).to eq({
          'first_name' => 'John', 'last_name' => {'first' => 'S'}
        })
      end
    end

    describe 'coerce_value' do
      class CoerceUser < TestUser
        def big_decimal
          BigDecimal('0.012')
        end

        def date_time
          DateTime.parse('2020-12-15T01:30:00-0500')
        end

        def time
          Time.parse('2020-12-16T01:30:00-0500')
        end
      end

      it 'serializes value to a standard format' do
        user = CoerceUser.create()
        expect(user.as_gql('big_decimal date_time time')).to eq({
          'big_decimal' => 0.012, 'date_time' => '2020-12-15T06:30:00Z', 'time' => '2020-12-16T06:30:00Z'
        })
      end
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
        user_hash = {snake_case: 'snake', camelCase: 'camel'}

        expect(user.as_gql('snake_case camelCase',
          {case: GqlSerializer::Configuration::CAMEL_CASE}))
          .to eq({'snakeCase' => 'snake', 'camelCase' => 'camel'})
        expect(user_hash.as_gql('snake_case camelCase',
          {case: GqlSerializer::Configuration::CAMEL_CASE}))
          .to eq({'snakeCase' => 'snake', 'camelCase' => 'camel'})
      end

      it 'converts keys to snake case' do
        user = CaseUser.create(name: 'John')
        user_hash = {snake_case: 'snake', camelCase: 'camel'}

        expect(user.as_gql('snake_case camelCase',
          {case: GqlSerializer::Configuration::SNAKE_CASE}))
        .to eq({'snake_case' => 'snake', 'camel_case' => 'camel'})
        expect(user_hash.as_gql('snake_case camelCase',
          {case: GqlSerializer::Configuration::SNAKE_CASE}))
          .to eq({'snake_case' => 'snake', 'camel_case' => 'camel'})
      end

      it 'uses the configured case by default' do
        GqlSerializer.configuration.case = GqlSerializer::Configuration::CAMEL_CASE
        user = CaseUser.create(name: 'John')

        expect(user.as_gql('snake_case camelCase'))
          .to eq({'snakeCase' => 'snake', 'camelCase' => 'camel'})

      ensure
        GqlSerializer.configuration.reset
      end
    end

    describe 'preload' do
      it 'reloads records when disabled' do
        original_user = TestUser.create(name: 'John', email: 'john@test.com')
        TestOrder.create(total: 5.0, test_user: original_user)
        same_user = TestUser.find(original_user.id)
        same_user.update(name: 'David')

        expect(original_user.as_gql('name email test_orders {total}', {preload: false}))
          .to eq({'name' => 'David', 'email' => 'john@test.com', 'test_orders' => [{'total' => 5.0}]})
      end

      it 'preloads records when enabled' do
        original_user = TestUser.create(name: 'John', email: 'john@test.com')
        TestOrder.create(total: 5.0, test_user: original_user)
        same_user = TestUser.find(original_user.id)
        same_user.update(name: 'David')

        expect(original_user.as_gql('name email test_orders {total}'))
          .to eq({'name' => 'John', 'email' => 'john@test.com', 'test_orders' => [{'total' => 5.0}]})
      end
    end
  end
end
