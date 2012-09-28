module VestalVersions
  
  class CommentForUpdateRequired < RuntimeError; end
  
  # Provides a way for comments/reason for update to be associated with specific 
  # versions
  
  module Comments
    extend ActiveSupport::Concern

    included do
      attr_accessor :reason_for_update
      
      # if update_comments is required, make sure we have one 
      # for updating old records and  when creating new records 
      # with initial version is turned on

      validates :reason_for_update, :presence => true, 
        :if => Proc.new{|item| 
          item.changed? &&
          item.vestal_versions_options[:update_comments] == :required && 
          (!item.new_record? || item.send(:create_initial_version?))
          }
    end


    module ClassMethods
      # After the original +prepare_versioned_options+ method cleans the given options, this alias
      # also extracts the <tt>:update_comments</tt> options
      # 
      # If the <tt>:update_comments</tt> is not set or set to :none, no reason for 
      # update will be stored.  If the option is set to :required, an exception 
      # will be thrown if reason for update is missing when updating a record.
      # Any other value is treated as :optional. which means reason will only be stored 
      # if one is supplied. 
      
      def prepare_versioned_options(options)
        result = super(options)
        self.vestal_versions_options[:update_comments] = options.delete(:update_comments)
        result
      end
    end

    # Methods added to versioned ActiveRecord::Base instances to enable versioning with 
    # additional column to store a comment or reason for updating
    private
      # Overrides the +version_attributes+ method to include a comment passed into the
      # parent object, by way of a +reason_for_update+ attr_accessor.
      def version_attributes
        comments_option = vestal_versions_options[:update_comments]
        # :none or not present
        if comments_option.blank? || comments_option == :none
          return super 
        end
        if comments_option == :required && reason_for_update.blank?
          raise CommentForUpdateRequired.new("Need a comment or reason for updating record.")
        end
        super.merge(:reason_for_update => reason_for_update)
      end

  end
end
