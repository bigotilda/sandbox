##
# inspiration for extending ActiveRecord from http://stackoverflow.com/questions/2328984/rails-extending-activerecordbase
#
# These additions add a class-wide DEFAULT value (and related accessor) to any active record class
module ActiveRecordExtension

  extend ActiveSupport::Concern
  
  # add your instance methods here

protected
  
  ##
  # Check for the default value being deleted (destroyed) and disallow this (this is hooked via :before_destroy callback
  # on the applicable models). Return FALSE to indicate the callback chain should be cancelled and reverted, TRUE if the 
  # destroy action can continue
  def disallow_default_destroy(display_name)
    if send(self.class.default_field) == self.class.default_value
      errors.add :base, "You cannot delete the default #{display_name}: '#{self.class.default_value}'"
      return false
    end
    true
  end
  
  ##
  # Update the members of the specified association collection so that their value for THIS object becomes the default
  # for the class of THIS, instead of THIS (since THIS will be destroyed soon and no longer valid).
  # 
  # @param assoc_coll: a symbol naming the name of the collection that needs their association to THIS updated to the default
  # @param accessor:   a symbol naming the accessor method that each member of the collection uses to access THIS
  def update_associated_to_default(assoc_coll, accessor)
    if send(assoc_coll).any?
      default_obj = self.class.default
      send(assoc_coll).each do |associate|
        associate.send("#{accessor}=", default_obj)
        associate.save
      end
    end
  end
  
  # add your static(class) methods here
  module ClassMethods
    ##
    # hacky way to set some class instance variables on the ActiveRecord::Base
    def set_extended_class_vars
      @default_field = :default
      @default_value = 'default'
    end
    
    ##
    # return the "default" object for this class, defined by @default_field and @default_value;
    # if the default object does not yet exist in the DB, it is first created; if the class
    # is not setup for a default, or setup incorrectly, nil is returned
    def default
      unless @default_field.blank?
        if self.respond_to? "find_by_#{@default_field}"
          default_obj = self.send("find_by_#{@default_field}", @default_value)
          if default_obj.blank?
            default_obj = self.create(@default_field => @default_value)
          end
          default_obj
        else
          nil
        end
      else
        nil
      end
    end
    
    ##
    # return the default_field
    def default_field() @default_field; end
      
    ##
    # return the default_value
    def default_value() @default_value; end
    
  end
end

# include the extension 
ActiveRecord::Base.send(:include, ActiveRecordExtension)

# init the vars we need
ActiveRecord::Base.send(:set_extended_class_vars)
