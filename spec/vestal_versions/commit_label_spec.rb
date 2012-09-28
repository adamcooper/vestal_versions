require 'spec_helper'

describe VestalVersions::Comments do
  let(:user){ User.create(:name => 'Steve Richert') }
  

  it 'defaults to nil' do
    user.update_attributes(:first_name => 'Stephen')
    user.versions.last.commit_label.should be_nil
  end

  it 'accept and return a label for update' do
    user.update_attributes(:first_name => 'Stephen', 
      :commit_label => "label A"  )
    user.versions.last.commit_label.should == "label A"
  end

  it "should allow duplicate labels" do
    user.update_attributes(:first_name => 'Stephen', 
      :commit_label => "label A"  )
    user.versions.last.commit_label.should == "label A"

    user.update_attributes(:first_name => 'Stephenie', 
      :commit_label => "label A"  )
    user.versions.last.commit_label.should == "label A"
  end

end
