require 'spec_helper'

class CalculationSet
  def call_me
    #stub, because flexmock doesn't work for new instances during constructor
    @@called=true
  end
  cattr_accessor :called
end
describe CalculationSet do
  
  before :all do
    CalculationSet.sets.clear
    @calc_set = CalculationSet.find("electricity_and_transport")
  end
  
  it 'can create an instance' do
    @calc_set.should be_a CalculationSet
  end

  it 'can create an instance' do
    @calc_set.calculations.should be_a ActiveSupport::OrderedHash
  end

  it "can access class sets hash" do
    CalculationSet.sets[:electricity_and_transport].should be_a CalculationSet
  end
  
  it "is included in class sets hash if initialised by find method" do
    CalculationSet.sets[:electricity_and_transport].should be_a CalculationSet
  end

  it "has file attribute if initialised by find method" do
    CalculationSet.sets[:electricity_and_transport].file.should eql "#{Rails.root}/config/calculations/electricity_and_transport.rb"
  end

  it "has name attribute if initialised by find method" do
    CalculationSet.sets[:electricity_and_transport].name.should eql "electricity_and_transport"
  end
  
  it "is included in class sets hash if initialised manually" do
    CalculationSet.new('my_set') {calculation {label :mycalc}}
    CalculationSet.sets[:my_set].should be_a CalculationSet
  end

  it "has name" do
    CalculationSet.new('my_set') {calculation {label :mycalc}}.name.should eql "my_set"
  end

  it 'can access a calculation by key' do
    @calc_set[:transport].should be_a PrototypeCalculation
  end

  describe "initialising from file" do

    after(:each) do
      CalculationSet.sets.clear
      delete_lock_files
    end

    it "should find config file in default Rails location using just file name" do
      CalculationSet.find_config_file("electricity").should eql "#{Rails.root}/config/calculations/electricity.rb"
    end

    it "should find config file in default Rails location using file name and extension" do
      CalculationSet.find_config_file("electricity.rb").should eql "#{Rails.root}/config/calculations/electricity.rb"
    end

    it "should find config file in other Rails location using relative path" do
      CalculationSet.find_config_file("config/electricity.rb").should eql "#{Rails.root}/config/electricity.rb"
    end

    it "should raise error if config file not found" do
      lambda{CalculationSet.find_config_file("fuel")}.should raise_error
    end

    it "should call load_set if no set exists in class hash" do
      CalculationSet.sets[:transport].should be_nil
      flexmock(AMEE::DataAbstraction::CalculationSet) do |mock|
        mock.should_receive(:load_set).once
      end
      set = CalculationSet.find('transport')
    end

    it "should not call load_set if set exists in class hash" do
      CalculationSet.sets[:transport].should be_nil
      set = CalculationSet.find('transport')
      CalculationSet.sets[:transport].should be_a CalculationSet
      flexmock(AMEE::DataAbstraction::CalculationSet) do |mock|
        mock.should_receive(:load_set).never
      end
      set = CalculationSet.find('transport')
    end

    it "should generate set from file name using find method" do
      CalculationSet.sets[:transport].should be_nil
      set = CalculationSet.find('transport')
      set.should be_a CalculationSet
      CalculationSet.sets[:transport].should be_a CalculationSet
      set.name.should eql 'transport'
      set.file.should eql "#{Rails.root}/config/calculations/transport.rb"
    end

    it "should regenerate lock file at default location" do
      lock_file = "#{Rails.root}/config/calculations/transport.lock.rb"
      File.exist?(lock_file).should be_false
      CalculationSet.sets[:transport].should be_nil
      set = CalculationSet.find('transport')
      File.exist?(lock_file).should be_false
      CalculationSet.sets[:transport].should be_a CalculationSet

      set.generate_lock_file
      File.exist?(lock_file).should be_true

      # lock file content
      content = File.open(lock_file).read

      # clear lock file to test for regenerated data
      File.open(lock_file,'w') {|file| file.write "overwrite content"}
      File.open(lock_file).read.should eql "overwrite content"
      File.exist?(lock_file).should be_true

      # regenerate and test content matches original
      CalculationSet.regenerate_lock_file('transport')
      File.exist?(lock_file).should be_true
      File.open(lock_file).read.should eql content
    end

    it "should regenerate lock file at custom location" do
      lock_file = "#{Rails.root}/config/calculations/transport.lock.rb"
      File.exist?(lock_file).should be_false
      CalculationSet.sets[:transport].should be_nil
      set = CalculationSet.find('transport')
      File.exist?(lock_file).should be_false
      CalculationSet.sets[:transport].should be_a CalculationSet

      set.generate_lock_file
      File.exist?(lock_file).should be_true

      content = File.open(lock_file).read
      File.open(lock_file,'w') {|file| file.write "overwrite content"}
      File.open(lock_file).read.should eql "overwrite content"
      File.exist?(lock_file).should be_true

      CalculationSet.regenerate_lock_file('transport', "#{Rails.root}/transport.lock.rb")
      File.exist?(lock_file).should be_true
      File.exist?("#{Rails.root}/transport.lock.rb").should be_true
      File.open(lock_file).read.should eql "overwrite content"
      File.open("#{Rails.root}/transport.lock.rb").read.should eql content

      File.delete("#{Rails.root}/transport.lock.rb")
    end

    it "should return a lock file path based on master config file" do
      set = CalculationSet.find('transport')
      set.lock_file_path.should eql "#{Rails.root}/config/calculations/transport.lock.rb"
    end

    it "should return lock file path if lock file exists" do
      lock_file = "#{Rails.root}/config/calculations/transport.lock.rb"
      File.exist?(lock_file).should be_false
      set = CalculationSet.find('transport')
      File.exist?(lock_file).should be_false
      set.generate_lock_file
      File.exist?(lock_file).should be_true
      set.config_path.should eql lock_file
    end

    it "should return master file path if lock file does not exist" do
      lock_file = "#{Rails.root}/config/calculations/transport.lock.rb"
      File.exist?(lock_file).should be_false
      set = CalculationSet.find('transport')
      File.exist?(lock_file).should be_false
      set.config_path.should eql "#{Rails.root}/config/calculations/transport.rb"
    end

    it "should know if lock file exists" do
      lock_file = "#{Rails.root}/config/calculations/transport.lock.rb"
      File.exist?(lock_file).should be_false
      set = CalculationSet.find('transport')
      File.exist?(lock_file).should be_false
      set.generate_lock_file
      File.exist?(lock_file).should be_true
      set.lock_file_exists?.should be_true
      File.delete(lock_file)
      File.exist?(lock_file).should be_false
      set.lock_file_exists?.should be_false
    end
    
    it "should generate lock file" do
      lock_file = "#{Rails.root}/config/calculations/transport.lock.rb"
      File.exist?(lock_file).should be_false

      set = CalculationSet.find('transport')
      File.exist?(lock_file).should be_false
      set.lock_file_exists?.should be_false

      set.generate_lock_file
      File.exist?(lock_file).should be_true
      set.lock_file_exists?.should be_true
      
      content = File.open(lock_file).read

      File.delete(lock_file)
      File.exist?(lock_file).should be_false
      set.lock_file_exists?.should be_false

      set.generate_lock_file
      File.exist?(lock_file).should be_true
      set.lock_file_exists?.should be_true
      File.open(lock_file).read.should eql content
    end

    it "should generate lock file at custom location" do
      lock_file = "#{Rails.root}/config/calculations/transport.lock.rb"
      File.exist?(lock_file).should be_false

      set = CalculationSet.find('transport')
      File.exist?(lock_file).should be_false
      set.lock_file_exists?.should be_false

      set.generate_lock_file("#{Rails.root}/transport.lock.rb")
      File.exist?(lock_file).should be_false
      set.lock_file_exists?.should be_false

      File.exist?("#{Rails.root}/transport.lock.rb").should be_true

      File.delete("#{Rails.root}/transport.lock.rb")
    end

  end

  it "can find a prototype calc without calc set" do
    CalculationSet.new('my_set') {
      calculation {label :my_calc}
      calculation {label :my_other_calc}
    }
    CalculationSet.new('your_set') {
      calculation {label :your_calc}
      calculation {label :your_other_calc}
    }
    CalculationSet.find_prototype_calculation(:transport).should be_a PrototypeCalculation
    CalculationSet.find_prototype_calculation(:your_calc).should be_a PrototypeCalculation
    CalculationSet.find_prototype_calculation(:my_other_calc).should be_a PrototypeCalculation
  end

  it "returns nil where no prototype calcualtion is found" do
    CalculationSet.find_prototype_calculation(:fuel).should be_nil
  end

  it 'can construct a calculation' do
    CalculationSet.new('my_set') {calculation {label :mycalc}}[:mycalc].should be_a PrototypeCalculation
  end

  it 'can be initialized with a DSL block' do
    CalculationSet.new('my_set') {call_me}
    CalculationSet.called.should be_true
  end

  it 'can have terms added to all calculations' do
    cs=CalculationSet.new('my_set') {
      all_calculations {
        drill {label :energetic}
      }
      calculation {
        label :mycalc
        drill {label :remarkably}
      }
    }
    cs[:mycalc].drills.labels.should eql [:remarkably,:energetic]
  end

  it 'can make multiple calculations quickly, one for each usage' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.usages(['bybob','byfrank']).
      item_definition.data_category.
      item_value_definition('first',['bybob'],[],'byfrank',[],nil,nil,true,false,nil,"TEXT").
      item_value_definition('second',['bybob'],[],'byfrank',[],nil,nil,true,false,nil,"TEXT").
      item_value_definition('third',['byfrank'],[],['bybob'],[],nil,nil,true,false,nil,"TEXT")
    cs=CalculationSet.new('my_set') {
      calculations_all_usages('/something') { |usage|
        label usage.to_sym
        profiles_from_usage usage
      }
    }
    cs[:bybob].profiles.labels.should eql [:first,:second]
    cs[:byfrank].profiles.labels.should eql [:third]
  end
  
end