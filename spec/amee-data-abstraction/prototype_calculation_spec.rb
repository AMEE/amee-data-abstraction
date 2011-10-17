require 'spec_helper'

class PrototypeCalculation
  def call_me
    #stub, because flexmock doesn't work for new instances during constructor
    @@called=true
  end
  cattr_accessor :called
end
describe PrototypeCalculation do
  before :all do
    @calc = CalculationSet.find("transport")[:transport]
  end
  
  it 'can create an instance' do
    @calc.should be_a PrototypeCalculation
  end
  it 'can be initialized with a DSL block' do
    PrototypeCalculation.new {call_me}
    PrototypeCalculation.called.should be_true
  end
  it 'can make a drill in the DSL block' do
    pc=PrototypeCalculation.new {drill{label :alpha}}
    pc[:alpha].should be_a Drill
  end
  it 'can set custom drill choices in the DSL block' do
    pc=PrototypeCalculation.new {drill{label :alpha; choices "ball","cat","dog"}}
    pc[:alpha].should be_a Drill
    pc[:alpha].choices.should eql ["ball","cat","dog"]
  end
  it 'can''t make a DSL block term without a label' do
    lambda{
      pc=PrototypeCalculation.new {drill}
    }.should raise_error Exceptions::DSL
  end
  it 'can make a profile item value in the DSL block' do
    pc=PrototypeCalculation.new {profile{label :alpha}}
    pc[:alpha].should be_a Profile
  end
  it 'can make an output in the DSL block' do
    pc=PrototypeCalculation.new {output{label :alpha}}
    pc[:alpha].should be_a Output
  end
  it 'can construct an ongoing calculation' do
    @calc.begin_calculation.should be_a OngoingCalculation
  end
  it 'should make the terms of the ongoing calculation be their own instances' do
    oc=@calc.begin_calculation
    oc[:distance].value :somevalue
    oc[:distance].value.should eql :somevalue
    @calc[:distance].value.should be_nil
  end
  it 'should copy name, path, label when cloning ongoing' do
    [:path,:name,:label].each do |property|
      @calc.begin_calculation.send(property).should eql @calc.send(property)
    end
  end
  it 'can autogenerate drill terms for itself, based on talking to amee' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.itemdef_drills ['first','second','third']
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',[],[],[],nil,nil,nil,false,true).
      item_value_definition('second',[],[],[],nil,nil,nil,false,true).
      item_value_definition('third',[],[],[],nil,nil,nil,false,true)
    pc=PrototypeCalculation.new {path '/something'; all_drills}
    pc.drills.labels.should eql [:first,:second,:third]
    pc.drills.names.should eql ['First','Second','Third']
  end
  it 'can autogenerate profile terms for itself' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',[],[],[],[],nil,nil,true,false,nil,"DOUBLE").
      item_value_definition('second',[],[],[],[],:kg,nil,true,false,nil,"DOUBLE").
      item_value_definition('third',[],[],[],[],nil,nil,true,false,nil,"DOUBLE")
    pc=PrototypeCalculation.new {path '/something'; all_profiles}
    pc.profiles.labels.should eql [:first,:second,:third]
    pc.profiles.default_units.first.should be_nil
    pc.profiles.default_units.compact.first.should be_a Quantify::Unit::Base
  end
  it 'can autogenerate profile terms for itself, based on a usage' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob'],[],[],[],nil,nil,true,false,nil,"DOUBLE").
      item_value_definition('second',['bybob'],[],[],[],:MBTU,:year,true,false,nil,"DOUBLE").
      item_value_definition('third',[],[],['bybob'],[],nil,nil,true,false,nil,"DOUBLE")
    pc=PrototypeCalculation.new {path '/something'; profiles_from_usage('bybob')}
    pc.profiles.labels.should eql [:first,:second]
    pc.profiles.default_units.first.should be_nil
    pc.profiles.default_units.compact.first.symbol.should eql 'MBTU'
    pc.profiles.default_per_units.compact.first.symbol.should eql 'yr'
  end
  it 'can generate profile terms with choices' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob'],[],[],['a','b'],nil,nil,true,false,nil,"DOUBLE").
      item_value_definition('second',['bybob'],[],[],[],nil,nil,true,false,nil,"DOUBLE").
      item_value_definition('third',[],[],['bybob'],[],nil,nil,true,false,nil,"DOUBLE")
    pc=PrototypeCalculation.new {path '/something'; profiles_from_usage('bybob')}
    pc[:first].choices.should eql ['a','b']
    pc[:first].interface.should eql :drop_down
    pc[:second].choices.should be_empty
    pc[:second].interface.should eql :text_box
  end
  it 'can generate profile terms with default values' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob'],[],[],['a','b'],nil,nil,true,false,"commercial","TEXT").
      item_value_definition('second',['bybob'],[],[],[],nil,nil,true,false,1200,"INTEGER").
      item_value_definition('third',['bybob'],[],[],[],nil,nil,true,false,nil,"DOUBLE")
    pc=PrototypeCalculation.new {path '/something'; profiles_from_usage('bybob')}
    pc[:first].value.should eql "commercial"
    pc[:second].value.should eql 1200
    pc[:third].value.should be_nil
  end
  it 'can generate profile terms with annotations' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob'],[],[],['a','b'],nil,nil,true,false,nil,"TEXT","Specify a number of something").
      item_value_definition('second',['bybob'],[],[],[],nil,nil,true,false,nil,"TEXT","Specify a number of something else").
      item_value_definition('third',['bybob'],[],[],[],nil,nil,true,false,nil,"TEXT")
    pc=PrototypeCalculation.new {path '/something'; profiles_from_usage('bybob')}
    pc[:first].note.should eql "Specify a number of something"
    pc[:second].note.should eql "Specify a number of something else"
    pc[:third].note.should be_nil
  end
  it 'can generate profile terms with types' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob'],[],[],['a','b'],nil,nil,true,false,nil,"DECIMAL").
      item_value_definition('second',['bybob'],[],[],[],nil,nil,true,false,nil,"TEXT").
      item_value_definition('third',['bybob'],[],[],[],nil,nil,true,false,'true',"BOOLEAN")
    pc=PrototypeCalculation.new {path '/something'; profiles_from_usage('bybob')}
    pc[:first].type.should eql "decimal"
    pc[:second].type.should eql "text"
    pc[:third].type.should eql "boolean"
    pc[:third].value.should be_true
  end
  it 'can select terms by usage with a longer list' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob'],[],'byfrank',[],nil,nil,true,false,nil,"TEXT").
      item_value_definition('second',['bybob'],[],'byfrank',[],nil,nil,true,false,nil,"TEXT").
      item_value_definition('third',['byfrank'],[],['bybob'],[],nil,nil,true,false,nil,"TEXT")
    pc=PrototypeCalculation.new {path '/something'; all_profiles ; fixed_usage 'bybob'}
    pc.profiles.in_use.labels.should eql [:first,:second]
    pc.profiles.out_of_use.labels.should eql [:third]
    pc.fixed_usage 'byfrank'
    pc.profiles.out_of_use.labels.should eql [:first,:second]
    pc.profiles.in_use.labels.should eql [:third]
  end
  it 'can generate itself with dynamic usage dropdown' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob'],[],'byfrank',[],:kg,:mi,true,false,nil,"TEXT").
      item_value_definition('second',['bybob'],[],'byfrank',[],:km,nil,true,false,nil,"TEXT").
      item_value_definition('third',['byfrank'],[],['bybob'],[],:lb,:h,true,false,nil,"TEXT")
    pc=PrototypeCalculation.new {path '/something'; usage{ value 'bybob'}}
    pc.profiles.labels.should eql [:first,:second,:third]
    pc.profiles.visible.labels.should eql [:first,:second]
    pc.terms.labels.should eql [:usage,:first,:second,:third]
    pc.terms.default_units.first.should be_nil
    pc.terms.default_units[1].should be_a Quantify::Unit::Base
    pc.terms.default_units[1].name.should eql 'kilogram'
    pc.terms.default_per_units.first.should be_nil
    pc.terms.default_per_units[1].should be_a Quantify::Unit::Base
    pc.terms.default_per_units[1].name.should eql 'mile'
    pc.terms.default_per_units[2].should be_nil
  end
  it 'can generate itself with outputs' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.return_value_definitions.
      item_definition.data_category.
      return_value_definition('first',:kg,:mi).
      return_value_definition('second',:km).
      return_value_definition('third')
    pc=PrototypeCalculation.new {path '/something'; all_outputs}
    pc.outputs.labels.should eql [:first,:second,:third]
    pc.terms.default_units.first.should be_a Quantify::Unit::Base
    pc.terms.default_units.first.name.should eql 'kilogram'
    pc.terms.default_per_units.first.should be_a Quantify::Unit::Base
    pc.terms.default_per_units.first.name.should eql 'mile'
    pc.terms.default_units[2].should be_nil
  end

  it 'can generate itself with everything' do
    mocker=AMEEMocker.new(self,:path=>'something')
    mocker.itemdef_drills ['first','second','third']
    mocker.return_value_definitions.
      item_value_definitions.
      item_definition.data_category.
      item_value_definition('first',['bybob','byfrank'],[],[],[],nil,nil,false,true,nil,"TEXT").
      item_value_definition('second',['bybob','byfrank'],[],[],[],nil,nil,false,true,nil,"TEXT").
      item_value_definition('third',['bybob','byfrank'],[],[],[],nil,nil,false,true,nil,"TEXT").
      item_value_definition('fourth',['bybob'],[],'byfrank',[],nil,nil,true,false,nil,"TEXT").
      item_value_definition('fifth',['bybob'],[],'byfrank',[],:lb,nil,true,false,nil,"TEXT").
      item_value_definition('sixth',['byfrank'],[],['bybob'],[],nil,nil,true,false,nil,"TEXT").
      return_value_definition('seventh').
      return_value_definition('eighth').
      return_value_definition('ninth',:mi,:h)
    pc=PrototypeCalculation.new {
      path '/something';
      terms_from_amee_dynamic_usage 'bybob'}
    pc.terms.labels.should eql [:usage,
      :first,:second,:third,
      :fourth,:fifth,:sixth,
      :seventh,:eighth,:ninth
    ]
    pc.terms.names.should eql ['Usage',
      'First','Second','Third',
      'Fourth','Fifth','Sixth',
      'Seventh','Eighth','Ninth'
    ]
    pc.terms.visible.labels.should eql  [:usage,
      :first,:second,:third,
      :fourth,:fifth,
      :seventh,:eighth,:ninth
    ]
    pc.terms.default_units.compact.first.should be_a Quantify::Unit::Base
    pc.terms.default_units.compact.map(&:name).should include 'pound'
    pc.terms.default_units.compact.map(&:name).should include 'mile'
    pc.terms.default_per_units.compact.first.should be_a Quantify::Unit::Base
    pc.terms.default_per_units.compact.map(&:name).should include 'hour'
  end
  it 'transfers memoised amee information to constructed ongoing calculations' do
    t=@calc.clone
    flexmock(AMEE::Data::Category).should_receive(:get).
      with(AMEE::DataAbstraction.connection,'/data/transport/car/generic').
      once.and_return(true)
    t.send(:amee_data_category)
    t.begin_calculation.send(:amee_data_category)
  end
  it 'can auto-create start and end date metadata' do
    t=@calc.clone
    t.instance_eval{
      start_and_end_dates
    }
    t.metadata.labels.should eql [:start_date,:end_date]
    t[:start_date].interface.should eql :date
    t[:start_date].date?.should be_true
    t.date.labels.should eql [:start_date,:end_date]
  end
  it 'can correct a dodgy term' do
    pc=PrototypeCalculation.new {
      metadatum{ label :frank }
      correcting(:frank) {name "Bob"}
    }
    pc[:frank].name.should eql "Bob"
  end
  it 'lets corrections on missing terms go' do
    lambda{pc=PrototypeCalculation.new {
      metadatum{ label :sid }
      correcting(:frank) {name "Bob"}
    }}.should_not raise_error
  end
end

