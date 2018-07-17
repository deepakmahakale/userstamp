require 'ostruct'

module Ddb #:nodoc:
  module Userstamp
    # Determines what default columns to use for recording the current stamper.
    # By default this is set to false, so the plug-in will use columns named
    # <tt>creator_id</tt>, <tt>updater_id</tt>, and <tt>deleter_id</tt>.
    #
    # To turn compatibility mode on, place the following line in your environment.rb
    # file:
    #
    #   Ddb::Userstamp.compatibility_mode = true
    #
    # This will cause the plug-in to use columns named <tt>created_by</tt>,
    # <tt>updated_by</tt>, and <tt>deleted_by</tt>.
    mattr_accessor :compatibility_mode
    @@compatibility_mode = false

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

          # What column should be used for the creator stamp?
          # Defaults to :creator_id when compatibility mode is off
          # Defaults to :created_by when compatibility mode is on
          class_attribute  :creator_attribute

          class_attribute  :creator_association

          # What column should be used for the updater stamp?
          # Defaults to :updater_id when compatibility mode is off
          # Defaults to :updated_by when compatibility mode is on
          class_attribute  :updater_attribute
          class_attribute  :updater_association

          # What column should be used for the deleter stamp?
          # Defaults to :deleter_id when compatibility mode is off
          # Defaults to :deleted_by when compatibility mode is on
          class_attribute  :deleter_attribute
          class_attribute  :deleter_association

          # Not all models in Enterprise have userstamps
          # self.stampable
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
          defaults  = {
                        :stamper_class_name => :user,
                      }.merge(options)

          self.stamper_class_name = defaults[:stamper_class_name].to_sym

          class_eval do
            belongs_to :created_by, :class_name => self.stamper_class_name.to_s.singularize.camelize,
                                    :foreign_key => :created_by_id
            alias_method :creator, :created_by
            alias_method :creator=, :created_by=

            belongs_to :updated_by, :class_name => self.stamper_class_name.to_s.singularize.camelize,
                                    :foreign_key => :updated_by_id
            alias_method :updater, :updated_by
            alias_method :updater=, :updated_by=

            before_save     :set_updater_attribute
            before_create   :set_creator_attribute

            if defined?(Caboose::Acts::Paranoid)
              belongs_to :deleted_by, :class_name => self.stamper_class_name.to_s.singularize.camelize,
                                      :foreign_key => :deleted_by_id
              alias_method :deleter, :deleted_by
              before_destroy  :set_deleter_attribute
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
          def has_stamper?
            !self.class.stamper_class.nil? && !self.class.stamper_class.stamper.nil? rescue false
          end

          def set_creator_attribute
            apply_stamper(:created_by, :created_by_id)
          end

          def set_updater_attribute
            apply_stamper(:updated_by, :updated_by_id)
          end

          def set_deleter_attribute
            if apply_stamper(:deleted_by, :deleted_by_id)
              save
            end
          end

          # Returns true if stampler applied, else nil
          def apply_stamper(association, attribute)
            return nil unless self.record_userstamp
            if has_stamper? && self.respond_to?(attribute)
              stamper_class = self.class.stamper_class
              stamper = stamper_class.stamper
              setter = if stamper.is_a?(stamper_class)
                association
              else
                attribute
              end

              if self.respond_to?(setter)
                self.send("#{setter}=", stamper)
                return true
              end
            end

            return nil
          end
        #end private
      end
    end
  end
end

ActiveRecord::Base.send(:include, Ddb::Userstamp::Stampable) if defined?(ActiveRecord)
