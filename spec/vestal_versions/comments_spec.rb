require 'spec_helper'

describe VestalVersions::Comments do
  let(:user){ User.create(:name => 'Steve Richert') }
  
  before do
    User.prepare_versioned_options(:update_comments => :optional)
  end

  it 'defaults to nil' do
    user.update_attributes(:first_name => 'Stephen')
    user.versions.last.reason_for_update.should be_nil
  end

  it 'accept and return a reason for update' do
    user.update_attributes(:first_name => 'Stephen', 
      :reason_for_update => "some reason", :updated_by => "me" )
    
    user.versions.last.reason_for_update.should == "some reason"
    user.versions.last.user_name.should == 'me'
  end
  
  it "should require a reason for update when configured" do
    User.prepare_versioned_options(:update_comments => :required)

    user.update_attributes(:first_name => 'Stephenie')
    user.should_not be_valid
    user.errors.should_not be_empty
    
    user.update_attributes(:first_name => 'Step', 
      :reason_for_update => "some reason")
    
    user.versions.last.reason_for_update.should == "some reason"
  end

  it "should not record a reason for update when not configured" do
    # not configured at all
    User.prepare_versioned_options(:update_comments => nil)
    user.update_attributes(:first_name => 'Stephen', 
      :reason_for_update => "some reason")

    user.versions.last.reason_for_update.should be_nil

    # configured for :none
    User.prepare_versioned_options(:update_comments => :none)
    user.update_attributes(:first_name => 'Stephen', 
      :reason_for_update => "some reason")

    user.versions.last.reason_for_update.should be_nil
  end

  it "should not validate reason for update on create without initial version turned on" do
    User.prepare_versioned_options(:update_comments => :required)
    someuser = User.create!(:name => "see boo")
    someuser.versions.size.should == 0

    someuser = User.create!(:name => "saw boo", :reason_for_update => "Ignored reason")
    someuser.versions.size.should == 0
  end

  it "should validate reason for update on create when initial version is true" do
    User.prepare_versioned_options(:initial_version => true, :update_comments => :required)
    someuser = User.new(:name => "boo hoo")
    someuser.should_not be_valid

    someuser = User.new(:name => "boo hoo", :reason_for_update => "some reason")
    someuser.should be_valid
    someuser.save!
    someuser.versions.size.should == 1
    someuser.versions.last.reason_for_update.should == "some reason"
  end
  

  it "should always validate reason for update on when updating old records" do
    User.prepare_versioned_options(:initial_version => true, :update_comments => :required)
    someuser = User.create!(:name => "boo hoo", :reason_for_update => "some reason")

    someuser.update_attributes(:name => "see more", :reason_for_update => nil)
    someuser.should_not be_valid

    someuser.update_attributes(:name => "see more", :reason_for_update => "")
    someuser.should_not be_valid

    someuser.update_attributes(:name => "see more", :reason_for_update => "finally a reason")
    someuser.should be_valid

    User.prepare_versioned_options(:initial_version => false, :update_comments => :required)
    someuser = User.create!(:name => "boo hoo boo")

    someuser.update_attributes(:name => "see more more")
    someuser.should_not be_valid

    someuser.update_attributes(:name => "see more more", :reason_for_update => nil)
    someuser.should_not be_valid

    someuser.update_attributes(:name => "see more more", :reason_for_update => "")
    someuser.should_not be_valid

    someuser.update_attributes(:name => "see more", :reason_for_update => "finally a reason")
    someuser.should be_valid

  end

  it "should still blow up when reason for udpate is required and validations are skipped " do
    User.prepare_versioned_options(:update_comments => :required)

    user.first_name = 'Stephenie'
    lambda {user.save(:validate => false)}.should raise_error
    
  end

  it "should not validate unless record has changed" do
    User.prepare_versioned_options(:update_comments => :required)
    user.update_attributes(:first_name => 'Stephenie', :reason_for_update => "nada")
    user.should be_valid
    
    u = User.find_by_id(user.id) 
    u.should be_valid
    # if we change something it should be invalid because we don't have a reason for update
    u.first_name = "Todd"
    u.should_not be_valid
    u.reason_for_update = "you look like a Todd to me"
    u.should be_valid
    
  end

end
