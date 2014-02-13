require 'spec_helper'

describe Role do


 context 'Check constants' do

 it "should have a fixed constant"  do
    Role.should have_constant(:ORGANIZATION_ADMIN_ROLE)
 end
 
  it "should have a fixed constant"  do
    Role.should have_constant(:ORGANIZATION_MANAGER_ROLE)
  end
  
  it "should have a fixed constant" do
    Role.should have_constant(:ORGANIZATION_USER_ROLE)
  end

 end

 context 'Create Roles' do 

  it 'creates a new admin role '  do 
    admin_role = FactoryGirl.create(:organization_admin)
    expect(admin_role.name).to eq 'organization_admin'
  end
 
  it 'creates a new manager role '  do 
    manager_role = FactoryGirl.create(:organization_manager)
    expect(manager_role.name).to eq 'organization_manager'
  end

  it 'creates a new user role '  do 
    user_role =  FactoryGirl.create(:organization_user)
	expect(user_role.name).to eq 'organization_user'
  end

 end
end
