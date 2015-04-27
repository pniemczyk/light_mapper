require 'spec_helper'

describe LightMapper do

  subject { original_hash.extend(LightMapper) }

  describe 'basic data mapping' do
    let(:original_hash) do
      {
        'A' => 'test',
        'b' => 1
      }
    end

    let(:maper) do
      {
        'A' => :a,
        'b' => 'z'
      }
    end

    it 'return correct hash' do
      expect(subject.mapping(maper)).to eq(a: original_hash['A'], 'z' => original_hash['b'])
    end
  end

  describe 'basic data mapping when keys are required' do
    let(:original_hash) do
      {
        'A' => 'test',
        'b' => 1
      }
    end

    let(:maper) do
      {
        'A' => :a,
        'c' => 'z'
      }
    end

    it 'raise KeyError when required key missing' do
      expect { subject.mapping(maper, require_keys: true) }.to raise_error(KeyError)
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

    let(:maper) do
      {
        'A' => :a,
        'c' => :c,
        b: 'z'
      }
    end

    it 'return correct hash' do
      expect(subject.mapping(maper, any_keys_kind: true)).to eq(
        a: original_hash['A'],
        c: original_hash[:c],
        'z' => original_hash['b']
      )
    end

    describe 'raise KeyError' do
      let(:maper) do
        {
          'A' => :a,
          'c' => :c,
          k: 'z'
        }
      end

      it ' when required key missing' do
        expect { subject.mapping(maper, require_keys: true, any_keys_kind: true) }.to raise_error(KeyError)
      end
    end
  end

  it 'nested keys'
end
