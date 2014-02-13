require 'spec_helper'

describe Organization do
  
  before(:each) do
   @admin_role =  FactoryGirl.create(:organization_admin)
   @manager_role = FactoryGirl.create(:organization_manager)
   @user_role =  FactoryGirl.create(:organization_user)
  end

  it 'creates a new organizaiton'  do 
    @organization = FactoryGirl.create(:organization)
    @organization.should be_valid
    @organization.should_not be_nil
  end

  describe 'creates a new organization user'do 
    before(:each) do
      @organization = FactoryGirl.create(:organization)
	  @user = OrganizationUser.find_by_organization_id(@organization.id)
    end

    context 'when it is valid' do 

      specify 'returns created organization user details' do
		expect(OrganizationUser.all).not_to be_empty 
		expect(@user).not_to be_nil	
      end

      specify 'should equal user orgazation with @organization' do 
	    expect(@user.organization).to eql @organization
	  end

	  specify 'should equal user role with @admin role' do 
	    expect(@user.roles).to eql [@admin_role]
      end

    end

  end
end 
