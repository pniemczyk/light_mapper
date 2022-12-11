require 'spec_helper'

class User
  attr_accessor :name, :email, :manager

  def initialize(name:, email:, manager: false)
    @name = name
    @email = email
    @manager = manager
  end

  def as_json
    { 'name' => name, 'email' => email, 'manager' => manager }
  end
end

describe LightMapper do

  subject { original_hash.extend(LightMapper) }

  describe 'basic data mapping' do
    let(:original_hash) do
      {
        'A' => 'test',
        'b' => 1
      }
    end

    let(:mapper) do
      {
        'A' => :a,
        'b' => 'z'
      }
    end

    it 'return correct hash' do
      expect(subject.mapping(mapper)).to eq(a: original_hash['A'], 'z' => original_hash['b'])
    end
  end

  describe 'basic data mapping when keys are required' do
    let(:original_hash) do
      {
        'A' => 'test',
        'b' => 1
      }
    end

    let(:mapper) do
      {
        'A' => :a,
        'c' => 'z'
      }
    end

    it 'raise KeyError when required key missing' do
      expect { subject.mapping(mapper, strict: true) }.to raise_error(LightMapper::KeyMissing)
    end
  end

  describe 'basic data mapping when any keys kind is allowed' do
    let(:original_hash) do
      {
        'A' => 'test',
        'b' => 1,
        c: 10

      }
    end

    let(:mapper) do
      {
        'A' => :a,
        'c' => :c,
        b: 'z'
      }
    end

    it 'return correct hash' do
      expect(subject.mapping(mapper, any_keys: true)).to eq(
                                                           a: original_hash['A'],
                                                           c: original_hash[:c],
                                                           'z' => original_hash['b']
                                                         )
    end

    describe 'raise KeyError' do
      let(:mapper) do
        {
          'A' => :a,
          'c' => :c,
          k: 'z'
        }
      end

      it ' when required key missing' do
        expect { subject.mapping(mapper, strict: true, any_keys: true) }.to raise_error(LightMapper::KeyMissing)
      end
    end
  end

  describe 'more advanced mapping' do
    let(:source) do
      {
        'source' => { 'google' => { 'search_word' => 'ruby' } },
        'user' => User.new(email: 'pawel@example.com', name: 'Pawel'),
        'roles' => %w[admin manager user],
        'mixed' => { users: [User.new(email: 'max@example.com', name: 'Max', manager: true), User.new(email: 'pawel@example.com', name: 'Pawel', manager: false)] },
        'scores' => [10, 2, 5, 1000],
        'last_4_payments' => [
          { 'amount' => 100, 'currency' => 'USD' },
          { 'amount' => 200, 'currency' => 'USD' },
          { 'amount' => 300, 'currency' => 'USD' },
          { 'amount' => 400, 'currency' => 'USD' }
        ],
        'array' => [
          [1, 2, 3],
          [4, 5, 6],
          [
            7,
            8,
            [':D']
          ],
        ]
      }
    end

    context 'with nested hash mapping' do
      let(:mapping) { { 'source.google.search_word' => :word } }

      it 'return correct result' do
        expect(source.extend(LightMapper).mapping(mapping)).to eq(word: 'ruby')
      end
    end

    context 'with nested array mapping' do
      let(:mapping) { { 'array.2.2.first' => :result } }

      it 'return correct result' do
        expect(source.extend(LightMapper).mapping(mapping)).to eq(result: ':D')
      end
    end

    context 'with nested object mapping' do
      let(:mapping) { { 'user.email' => :result } }

      it 'return correct result' do
        expect(source.extend(LightMapper).mapping(mapping)).to eq(result: 'pawel@example.com')
      end
    end

    context 'with mapping proc' do
      let(:mapping) { { (->(source) { source['last_4_payments'].last['amount'].to_s }) => :result } }

      it 'return correct result' do
        expect(source.extend(LightMapper).mapping(mapping)).to eq(result: '400')
      end
    end

    context 'with mix of nested object types' do
      let(:mapping) do
        {
          'source.google.search_word' => :word,
          'user.email' => :email,
          'user.as_json.name' => :name,
          'roles.0' => :first_role,
          ['roles', 1] => :middle_role,
          'roles.last' => :last_role,
          (->(source) { source['mixed'][:users].find { |user| user.manager }.email }) => :manager_email,
          (->(source) { source['mixed'][:users].find { |user| user.manager }.name }) => :manager_name,
          'mixed.users.last.name' => :last_user_name,
          (->(source) { source['last_4_payments'].map(&:values).map(&:first).max }) => :quarterly_payment_amount,
          'scores.sum' => :final_score,
          'array.2.2.first' => :smile
        }
      end

      it 'return correct result' do
        expect(source.extend(LightMapper).mapping(mapping, any_keys: true)).to match({
                                                                                       word: 'ruby',
                                                                                       email: 'pawel@example.com',
                                                                                       name: 'Pawel',
                                                                                       final_score: 1017,
                                                                                       first_role: 'admin',
                                                                                       last_role: 'user',
                                                                                       manager_email: 'max@example.com',
                                                                                       manager_name: 'Max',
                                                                                       last_user_name: 'Pawel',
                                                                                       middle_role: 'manager',
                                                                                       quarterly_payment_amount: 400,
                                                                                       smile: ':D'
                                                                                     })
      end

      it 'return correct result base on proper key types' do
        expect(source.extend(LightMapper).mapping(mapping)).to match({
                                                                       word: 'ruby',
                                                                       email: 'pawel@example.com',
                                                                       name: 'Pawel',
                                                                       final_score: 1017,
                                                                       first_role: 'admin',
                                                                       last_role: 'user',
                                                                       manager_email: 'max@example.com',
                                                                       manager_name: 'Max',
                                                                       last_user_name: nil,
                                                                       middle_role: 'manager',
                                                                       quarterly_payment_amount: 400,
                                                                       smile: ':D'
                                                                     })
      end

      it 'raise KeyMissing error' do
        expect { source.extend(LightMapper).mapping({ 'user.non_existence_method' => :result }, strict: true) }.to raise_error(LightMapper::KeyMissing)
        expect { source.extend(LightMapper).mapping({ 'last_4_payments.4' => :result }, strict: true) }.to raise_error(LightMapper::KeyMissing)
        expect { source.extend(LightMapper).mapping({ 'source.google.missing_key' => :result }, strict: true) }.to raise_error(LightMapper::KeyMissing)
      end
    end

    context 'nested input to nested output' do
      let(:source) do
        {
          'source' => { 'google' => { 'private_pool' => true } },
          'user' => User.new(email: 'pawel@example.com', name: 'Pawel'),
          'roles' => %w[admin manager user],
          'scores' => [10, 2, 5, 1000],
          'last_4_payments' => [
            { 'amount' => 100, 'currency' => 'USD' },
            { 'amount' => 200, 'currency' => 'USD' },
            { 'amount' => 300, 'currency' => 'USD' },
            { 'amount' => 400, 'currency' => 'USD' }
          ]
        }
      end

      let(:mapping) do
        {
          'source.google.private_pool' => 'private',
          'user.email' => 'user.email',
          'user.name' => 'user.name',
          'roles' => 'user.roles',
          'scores.max' => 'user.best_score',
          'last_4_payments.last' => 'payment.last',
        }
      end

      it 'return correct result' do
        expect(source.extend(LightMapper).mapping(mapping, keys: :symbol)).to match({
                                                                                      private: true,
                                                                                      user: {
                                                                                        email: 'pawel@example.com',
                                                                                        name: 'Pawel',
                                                                                        roles: %w[admin manager user],
                                                                                        best_score: 1000,
                                                                                      },
                                                                                      payment: {
                                                                                        last: { 'amount' => 400, 'currency' => 'USD' }
                                                                                      }
                                                                                    })
      end

      it 'raise AlreadyAssignedValue error when key was allready assigned' do
        expect { source.extend(LightMapper).mapping('source.google.private_pool' => 'private', 'source.google' => 'private') }.to raise_error(LightMapper::AlreadyAssignedValue)
      end
    end
  end
end
