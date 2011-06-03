
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hash do
  before(:each) do
    @hash = { 'first_name' => 'Kenny',
              'last_name' => 'Rogers',
              'date_of_birth' => {'day' => 17,
                                  'month' => 'April',
                                  'year' => 1939 },
              'interests' => [ {'movie' => 'Birds',
                                'book' => 'Catch 22'},
                               "guitar",
                               {'song' => 'Leaving On a Jetplane'} ],
              :already_a_symbol => 'dummy' }
  end

  it "should symbolize keys, returning new hash" do
    new_hash = @hash.recursive_symbolize_keys
    new_hash.keys.size.should eql 5
    new_hash.keys.each { |k| k.should be_a Symbol }
    new_hash[:first_name].should eql 'Kenny'
    new_hash[:date_of_birth].should be_a Hash
    new_hash[:date_of_birth].keys.each { |k| k.should be_a Symbol }
    new_hash[:date_of_birth][:month].should eql 'April'
    new_hash[:interests].should be_a Array
    new_hash[:interests][0].keys.each { |k| k.should be_a Symbol }
    new_hash[:interests][0][:movie].should eql 'Birds'
  end

  it "should symbolize keys in place, returning self" do
    @hash.recursive_symbolize_keys!
    @hash.keys.size.should eql 5
    @hash.keys.each { |k| k.should be_a Symbol }
    @hash[:first_name].should eql 'Kenny'
    @hash[:date_of_birth].should be_a Hash
    @hash[:date_of_birth].keys.each { |k| k.should be_a Symbol }
    @hash[:date_of_birth][:month].should eql 'April'
    @hash[:interests].should be_a Array
    @hash[:interests][0].keys.each { |k| k.should be_a Symbol }
    @hash[:interests][0][:movie].should eql 'Birds'
  end
end

