module VestalVersions
  
  # Provides a way for free form for label to be associated with specific 
  # versions
  
  module CommitLabel
    extend ActiveSupport::Concern

    included do
      attr_accessor :commit_label
    end


    module ClassMethods
    end

    # Methods added to versioned ActiveRecord::Base instances to enable versioning with 
    # additional column to store a comment or reason for updating
    private
      # Overrides the +version_attributes+ method to include label passed into the
      # parent object, by way of a +commit_label+ attr_accessor.
      def version_attributes
        super.merge(:commit_label => commit_label)
      end

  end
end
