require 'spec_helper'

describe VestalVersions::Versions do
  let(:user){ User.create(:name => 'Stephen Richert') }

  before do
    user.update_attribute(:name, 'Steve Jobs')
    user.update_attribute(:last_name, 'Richert')
    @first_version, @last_version = user.versions.first, user.versions.last
  end

  it 'is comparable to another version based on version number' do
    @first_version.should == @first_version
    @last_version.should == @last_version
    @first_version.should_not == @last_version
    @last_version.should_not == @first_version
    @first_version.should < @last_version
    @last_version.should > @first_version
    @first_version.should <= @last_version
    @last_version.should >= @first_version
  end

  it "is not equal a separate model's version with the same number" do
    other = User.create(:name => 'Stephen Richert')
    other.update_attribute(:name, 'Steve Jobs')
    other.update_attribute(:last_name, 'Richert')
    first_version, last_version = other.versions.first, other.versions.last

    @first_version.should_not == first_version
    @last_version.should_not == last_version
  end

  it 'defaults to ordering by number when finding through association' do
    numbers = user.versions.map(&:number)
    numbers.sort.should == numbers
  end

  it 'returns true for the "initial?" method when the version number is 1' do
    version = user.versions.build(:number => 1)
    version.number.should == 1
    version.should be_initial
  end
  
  it "return the version number if it is not a revert" do
    user.version.should == user.versions.last.original_number
  end

  it "return the reverted_version if it is a revert" do
    user.revert_to!(1)
    user.versions.last.original_number.should == 1
  end

  it "return the original version if it is a double revert" do
    user.revert_to!(2)
    version = user.version
    user.update_attributes(:last_name => 'Gates')
    user.revert_to!(version)
    user.versions.last.original_number.should == 2
  end

  it "revert when number column is renamed" do
    VestalVersions::Version.config.number_column_name = "elnumero"
    u = User.create!(:name => "foo bars")
    u.update_attributes(:name => "snooze bars")
    u.update_attributes(:name => "candy bars")
    
    u.revert_to!(1)
    u.name.should == "foo bars"
    u.versions.last.original_number.should == 1
  end


  it "should default to 'number' as the version number column" do
    VestalVersions::Version.number_column_name.should == 'number'
  end

  it "should use configured colum name as the version number column" do
    VestalVersions::Version.config.number_column_name = "elnumero"
    VestalVersions::Version.number_column_name.should == 'elnumero'
  end

  it "should store version number in alternate column name if configured" do
    User.delete_all
    VestalVersions::Version.delete_all
    VestalVersions::Version.config.number_column_name = "elnumero"
    user = User.create(:name => 'Stephen Richert')
    user.versions.should be_empty
        
    user.update_attribute(:name, 'Steve Jobs')
    user.versions.size.should == 1
    user.versions.last.number.should == 2
    user.versions.last[:elnumero].should == 2
    user.versions.last[:number].should be_nil
        
    user.update_attribute(:name, 'Steven Forbes')
    user.versions.size.should == 2
    user.versions.last.number.should == 3
    user.versions.last[:elnumero].should == 3
    user.versions.last[:number].should be_nil
  
    
  end
  
end
