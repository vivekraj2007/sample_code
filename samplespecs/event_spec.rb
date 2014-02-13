require 'spec_helper'

describe Event do


 describe 'Basic Event'  do
	
  before(:each) do 
 	@admin_role =  FactoryGirl.create(:organization_admin)
	@organization = FactoryGirl.create(:organization)
 	@event = FactoryGirl.build(:complete_event)
        @event.organization = @organization
	@event.save
  end	

  it 'should check abilities' do 
    ou = OrganizationUser.first
    ability = Ability.new(ou.user,@organization)
    ability.should be_able_to(:manage, Event) 
  end

  it 'should creates a new event' do 
    @event.should be_valid
    @event.should_not be_nil
    @event.class.should eql ::Event
  end
  
  it 'should find event by id' do 
	event = Event.find(@event.id)
	expect(event.name).to eql @event.name
  end

  it 'should require city' do 
    event = Event.create(:name => 'sample event')
    event.should_not be_valid
    event.errors.full_messages.should include "City can't be blank"	
  end
	
  it 'should require state' do 
    event = Event.create(:name => 'sample event')
    event.should_not be_valid
    event.errors.full_messages.should include "State can't be blank"
  end

  it 'should require zip' do 
    event = Event.create(:name => 'sample event')
    event.should_not be_valid
    event.errors.full_messages.should include "Zip can't be blank"
  end

  it 'should require time zone' do 
    event = Event.create(:name => 'sample event')
	event.should_not be_valid
    event.errors.full_messages.should include "Time zone can't be blank"
  end
 

   context 'is valid' do 
   
    specify 'when it relates to organization' do 
      expect(@event).to respond_to(:organization)
    end

    specify 'when it relates to host'  do 
      expect(@event).to respond_to(:host)
    end

    specify 'when it relates organization'  do 
      expect(@event.organization.uri_name).not_to be_nil
      expect(@event.organization.uri_name).to eql @organization.uri_name
    end
	
   end

 end



end
