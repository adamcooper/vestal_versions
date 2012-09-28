require 'spec_helper'

describe VestalVersions::Deletion do
  let(:name){ 'Steve Richert' }
  subject{ DeletedUser.create(:first_name => 'Steve', :last_name => 'Richert') }

  context "a deleted version's changes" do

    before do
      subject.update_attribute(:last_name, 'Jobs')
    end

    it "removes the original record" do
      subject.destroy

      DeletedUser.find_by_id(subject.id).should be_nil
    end

    it "creates another version record" do
      expect{ subject.destroy }.to change{ VestalVersions::Version.count }.by(1)
    end

    it "creates a version with a tag 'deleted'" do
      subject.destroy
      VestalVersions::Version.last.tag.should == 'deleted'
    end

  end

  context "deletion tracking" do
    subject{ DeletedUser.create(:first_name => 'Steve', :last_name => 'Richert') }
    let(:admin_user){ User.create(:name => 'Steve Yobs') }

    it "should track who destroyed a record from a name" do
      subject.update_attributes(:updated_by => "SYSTEM", :reason_for_update => "no longer needed", :commit_label => "labelA")
      subject.destroy
      DeletedUser.find_by_id(subject.id).should be_nil
      
      version_record = VestalVersions::Version.last
      version_record.tag.should == 'deleted'
      version_record.reason_for_update.should == "no longer needed"
      version_record.commit_label.should == "labelA"
      version_record.user_name.should == "SYSTEM"
    end

    it "should track who destroyed a record given a real user" do
      subject.update_attributes(:updated_by => admin_user, :reason_for_update => "no longer needed", :commit_label => "labelA")
      subject.destroy
      DeletedUser.find_by_id(subject.id).should be_nil
      
      version_record = VestalVersions::Version.last
      version_record.tag.should == 'deleted'
      version_record.reason_for_update.should == "no longer needed"
      version_record.commit_label.should == "labelA"
      version_record.user_id.should == admin_user.id
      version_record.user_type.should == "User"
    end
  end

  context "deleted versions" do
    let(:last_version){ VestalVersions::Version.last }
    before do
      subject.update_attribute(:last_name, 'Jobs')
      subject.destroy
    end

    context "restoring a record with a bang" do
      it "is able to restore the user record" do
        last_version.restore!

        last_version.versioned.should == subject
      end

      it "removes the last versioned entry" do
        expect{
          last_version.restore!
        }.to change{ VestalVersions::Version.count }.by(-1)
      end

      it "works properly even if it's not on the proper version" do
        another_version = VestalVersions::Version.where(
          :versioned_id   => last_version.versioned_id,
          :versioned_type => last_version.versioned_type
        ).first

        another_version.should_not == last_version

        another_version.restore!.should == subject
      end

      it "restores even if the schema has changed" do
        new_mods = last_version.modifications.merge(:old_column => 'old')
        last_version.update_attributes(:modifications => new_mods)

        last_version.restore.should == subject
      end
    end
    
    context "deleting new records or already destroyed records" do
      it "does not create record for new records to be deleted" do
        new_subject = DeletedUser.new(:first_name => 'Steve', :last_name => 'Richert')
        old_count = VestalVersions::Version.count
        new_subject.destroy
        VestalVersions::Version.count.should == old_count # no new versions created
      end
      
      it "does not create versions for records already deleted" do
        new_subject = DeletedUser.create(:first_name => 'Steve', :last_name => 'Richert')
        new_subject.destroy
        new_subject.should be_destroyed
        old_count = VestalVersions::Version.count
        new_subject.destroy # couble destroy
        VestalVersions::Version.count.should == old_count # no new versions created
      end

    end

    context "restoring a record without a save" do
      it "does not save the DeletedUser when restoring" do
        last_version.restore.should be_new_record
      end

      it "restores the user object properly" do
        last_version.restore.should == subject
      end

      it "does not decrement the versions table" do
        expect{
          last_version.restore
        }.to change{ VestalVersions::Version.count }.by(0)
      end
    end
  end

end
