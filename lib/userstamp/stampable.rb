require 'ostruct'

module Ddb #:nodoc:
  module Userstamp
    # Extends the stamping functionality of ActiveRecord by automatically recording the model
    # responsible for creating, updating, and deleting the current object. See the Stamper
    # and Userstamp modules for further documentation on how the entire process works.
    module Stampable
      def self.included(base) #:nodoc:
        super

        base.extend(ClassMethods)
        base.class_eval do
          include InstanceMethods

          # Should ActiveRecord record userstamps? Defaults to true.
          class_attribute  :record_userstamp
          self.record_userstamp = true

          # Which class is responsible for stamping? Defaults to :user.
          class_attribute  :stamper_class_name
        end
      end

      module ClassMethods
        # This method is automatically called on for all classes that inherit from
        # ActiveRecord, but if you need to customize how the plug-in functions, this is the
        # method to use. Here's an example:
        #
        #   class Post < ActiveRecord::Base
        #     stampable :stamper_class_name => :person
        #   end
        #
        # The method will automatically setup all the associations, and create <tt>before_save</tt>
        # and <tt>before_create</tt> filters for doing the stamping.
        def stampable(options = {})
          stamper_class_name = options.fetch(:stamper_class_name, :user).to_sym

          self.stamper_class_name = stamper_class_name

          class_eval do
            # created_by
            belongs_to :created_by, :class_name => self.stamper_class_name.to_s.singularize.camelize,
                                    :foreign_key => :created_by_id
            alias_method :creator,  :created_by
            alias_method :creator=, :created_by=
            before_create :userstamp_set_creator_attribute

            # updated_by
            belongs_to :updated_by, :class_name => self.stamper_class_name.to_s.singularize.camelize,
                                    :foreign_key => :updated_by_id
            alias_method :updater,  :updated_by
            alias_method :updater=, :updated_by=
            before_save :userstamp_set_updater_attribute

            if defined?(Caboose::Acts::Paranoid)
              belongs_to :deleted_by, :class_name => self.stamper_class_name.to_s.singularize.camelize,
                                      :foreign_key => :deleted_by_id
              alias_method :deleter,  :deleted_by
              alias_method :deleter=, :deleted_by=
              before_destroy :userstamp_set_deleter_attribute
            end
          end
        end

        # Temporarily allows you to turn stamping off. For example:
        #
        #   Post.without_stamps do
        #     post = Post.find(params[:id])
        #     post.update_attributes(params[:post])
        #     post.save
        #   end
        def without_stamps
          original_value = self.record_userstamp
          self.record_userstamp = false
          yield
          self.record_userstamp = original_value
        end

        def stamper_class #:nodoc:
          stamper_class_name.to_s.capitalize.constantize rescue nil
        end
      end

      module InstanceMethods #:nodoc:
        private
          def userstamp_has_stamper?
            !self.class.stamper_class.nil? && !self.class.stamper_class.stamper.nil? rescue false
          end

          def userstamp_set_creator_attribute
            userstamp_apply_stamper(:created_by, :created_by_id)
          end

          def userstamp_set_updater_attribute
            userstamp_apply_stamper(:updated_by, :updated_by_id)
          end

          def userstamp_set_deleter_attribute
            if userstamp_apply_stamper(:deleted_by, :deleted_by_id)
              save
            end
          end

          # Returns true if stampler applied, else nil
          def userstamp_apply_stamper(association, attribute)
            # Do nothing if the attribute does not exist in the table or
            # we are not recording userstamps.
            return nil if !self.record_userstamp || !self.class.columns_hash.has_key?(attribute.to_s)

            if userstamp_has_stamper?
              stamper_class = self.class.stamper_class
              stamper = stamper_class.stamper
              setter = if stamper.is_a?(stamper_class)
                association
              else
                attribute
              end

              self.send("#{setter}=", stamper)
              true   # Return true to indicate we set the stamper
            end
          end
        #end private
      end
    end
  end
end

ActiveRecord::Base.send(:include, Ddb::Userstamp::Stampable) if defined?(ActiveRecord)
