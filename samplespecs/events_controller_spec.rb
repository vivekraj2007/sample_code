require 'spec_helper'

describe Admin::EventsController do
  login_admin

  def valid_attributes 
   {"organization_uri_name"=> @organization.uri_name}
  end


  def event_attrbs
  {"event"=>
    {"name" => "my_new_event",
      "private"=>"0",
   	  "validate_dates"=>"true",
   	  "time_zone"=>"Chennai",
          "starts_at_date"=>"12/16/2013",
   	  "starts_at_hour"=>"03",
   	  "starts_at_minute"=>"",
   	  "starts_at_meridian"=>"AM",
   	  "has_end_date"=>"1",
   	  "ends_at_date"=>"12/23/2023",
   	  "ends_at_hour"=>"04",
   	  "ends_at_minute"=>"45",
   	  "ends_at_meridian"=>"PM",
   	  "hours_info"=>"",
   	  "address_name" => "my address name",
   	  "address" => "myaddress",
   	  "city" => "mycity",
   	  "state"=>"mystate",
   	  "zip" => "123456" ,
   	  "country" => "mycountry",
   	  "contact_name"=>"myname",
   	  "contact_phone"=>"12345678",
   	  "contact_email" => "test_user@example.com",
   	  "exhibitor_registration_enabled"=>"1",
   	  "description" =>"sample description about event" 
    },
   	"organization_uri_name"=> @organization.uri_name
  }

  end

  def create_event 
    @event = FactoryGirl.build(:complete_event)
    @event.organization = @organization
    @event.save
    @event
  end


  describe 'GET index' do
    it 'assigns all events as @events' do
      create_event
      get :index, valid_attributes
      assigns(:events).should eq([@event])
    end
  end



  describe 'GET show' do

    before(:each) do 
      create_event
      @attributes = valid_attributes
      @attributes.merge!("id" => @event.uuid)
    end
	
    it 'assigns the requested event as @event' do
      get :show, @attributes
      assigns(:event).should eq(@event)
    end

    it 'should redirects to dashboard_admin_event_path' do 
      get :show, @attributes
      response.should redirect_to dashboard_admin_event_path(@event)
    end

  end

  describe 'GET new' do
    it 'assigns a new organization as @organization' do
      get :new, {}
      assigns(:event).should be_a_new(Event)
    end
  end



  describe 'POST create' do
   
    describe 'with valid params' do
		
      before(:each) do 
	FactoryGirl.create(:acl_role_owner)
	#FactoryGirl.create(:acl_role_manager)
	#FactoryGirl.create(:acl_role_reporter)
	#FactoryGirl.create(:acl_role_helper)
	#FactoryGirl.create(:acl_role_helper_manger)
	#FactoryGirl.create(:acl_role_editor)
      end

      it 'creates a new Event'  do
        expect { post :create, event_attrbs }.to change(Event, :count).by(1)
      end

      it 'assigns a newly created event as @event' do
        post :create, event_attrbs
        assigns(:event).should be_a(Event)
        assigns(:event).should be_persisted
      end

    end

    describe 'with invalid params' do
      it 'assigns a newly created but unsaved event as @event' do
        Event.any_instance.stub(:save).and_return(false)
        post :create, event_attrbs
        assigns(:event).should be_a_new(Event)
      end

      it 're-renders the :new template' do
        Event.any_instance.stub(:save).and_return(false)
        post :create, event_attrbs
        response.should render_template(:new)
      end
    end
  end


  describe "PUT update"  do
    
    before(:each) do 
      @event = FactoryGirl.create(:complete_event, :organization => @organization)
    end 

    describe "with valid params"  do
      it "updates the requested event" do
        put :update, { :id => @event.uuid ,  :event => { "name" => "Newevent" } , "organization_uri_name"=> @organization.uri_name }
	expect(response.status).to eql 302
	expect(Event.find(@event.id).name).to eql 'Newevent'
      end

      it "assigns the requested event as @event" do
        put :update, { :id => @event.uuid ,  :event => { "time_zone"=>"Kolkata" } , "organization_uri_name"=> @organization.uri_name }
        assigns(:event).should eq(@event)
      end

      it "redirects to the @event"  do
        put :update, { :id => @event.uuid ,  :event => { "time_zone"=>"Kolkata" } , "organization_uri_name"=> @organization.uri_name }
        response.should redirect_to edit_home_admin_event_path(@event)
      end
    end

    describe "with invalid params" do
      it "assigns the event as @event" do
        Event.any_instance.stub(:save).and_return(false)
        put :update, { :id => @event.uuid ,  :event => { "time_zone"=>"Kolkata" } , "organization_uri_name"=> @organization.uri_name }
        assigns(:event).should eq(@event)
      end

      it "re-renders the 'edit' template" do
        Event.any_instance.stub(:save).and_return(false)
        put :update, { :id => @event.uuid ,  :event => { "time_zone"=>"Kolkata" } , "organization_uri_name"=> @organization.uri_name }
        response.should render_template("edit")
      end
    end
  end

   describe "DELETE destroy" do

    before(:each) do 
      @event = FactoryGirl.create(:complete_event, :organization => @organization)
    end 

    it "destroys the requested @event" do
      expect { delete :destroy, { :id => @event.uuid , "organization_uri_name"=> @organization.uri_name } }.to change(Event, :count).by(-1)
    end

    it "redirects to the admin events list" do
      delete :destroy, {:id => @event.uuid , "organization_uri_name"=> @organization.uri_name }
      response.should redirect_to admin_events_path
    end
  end

end
