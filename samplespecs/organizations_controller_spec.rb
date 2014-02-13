require 'spec_helper'

describe OrganizationsController do
  login_admin

  def valid_attributes
   {"name"=>"test_org",
    "uri_name"=>"test_org",
    "admin_email"=>"test_org@example.com",
    "admin_first_name"=>"test_org_first_name",
    "admin_last_name"=>"test_org_last_name",
   }
  end

  before(:each) do 
    @role = FactoryGirl.create(:organization_admin)
    request.env['HTTPS'] = 'on'
  end

  describe 'GET index' do
    it 'redirects to organizations' do 
      get :index, {}
      response.should redirect_to("/admin/organizations")
    end
  end

  describe 'GET show' do
    it 'assigns the requested organization as @organization' do
      #organization = FactoryGirl.create(:organization)
      get :show, {:id => @organization.uuid}
      assigns(:organization).should eq(@organization)
    end
  end

  describe 'GET new' do
    it 'assigns a new organization as @organization' do
      get :new, {}
      assigns(:organization).should be_a_new(Organization)
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'creates a new Organization'  do
        expect { post :create, {:organization => valid_attributes} }.to change(Organization, :count).by(1)
      end

      it 'assigns a newly created organization as @organization' do
        post :create, {:organization => valid_attributes}
        assigns(:organization).should be_a(Organization)
        assigns(:organization).should be_persisted
      end

    end

    describe 'with invalid params' do
      it 'assigns a newly created but unsaved organization as @organization' do
        Organization.any_instance.stub(:save).and_return(false)
        post :create, {:organization => {name: 'Sample Org',uri_name: 'sample_uri'}}
        assigns(:organization).should be_a_new(Organization)
      end

      it 're-renders the :new template' do
        Organization.any_instance.stub(:save).and_return(false)
        post :create, {:organization => {name:'',uri_name: 'sample_uri' }}
        response.should render_template(:new)
      end
    end
  end


end
