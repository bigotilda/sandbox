##
# This is a snippet of an ActiveRecord class from my proprietary work that represents a tree-structured
# data set. The interesting (imo) parts are the tree traversal methods which I've left in below.
#
# -----
#
# The hierarchy of available request types that a ticket can be. There are a set of top-level
# request types which then each have a set of sub-categories (children), which in turn can have
# their own sub-categories, etc. This allows tickets to be assigned to a specific grouping.
#
class RequestType < ActiveRecord::Base  
 
  #--- SNIP (removed various associations, scopes, etc that are pretty standard in a Rails ActiveRecord class) ---#
  # .
  # .
  # .
  #--- /SNIP ---#
  
  #--- Instance Methods ---#
    
  ##
  # Deactivate this RQ and all its descendants
  def deactivate
    traverse_down {|rq| rq.update_attributes(:active => false) }
  end
  
  ##
  # Return the parent request type, or nil if the request type is at the top-level or if the parent cannot be found
  def parent
    return nil if parent_id == 0 || parent_id.blank?
    begin
      return RequestType.find(parent_id)
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end
   
  ##
  # @return Array: array of RequestType instances, ordered in ancestral order from closest (the parent)
  # to furthest (the root/top-level RequestType) 
  def get_ancestors
    # the database SHOULD be setup correctly with parents all properly tied together
    # and root types having parent_id of 0
    ancestors = []
    parent_id = self.parent_id
    
    # 0 parent_id means we're at the top level, so no more parents.
    while parent_id != 0
      begin
        parent_request = RequestType.find(parent_id)
        ancestors << parent_request
        parent_id = parent_request.parent_id
      rescue ActiveRecord::RecordNotFound
        # parent element couldn't be found, which shouldn't happen; for now just break and return what
        # we've found so far
        break
      end
    end
    
    # return the array of ancestors
    ancestors
  end
  
  ##
  # @return Array: array of this request type's children
  def get_children
    RequestType.find_all_by_parent_id(id)
  end
  
  ##
  # @return Array: array of all the descendants of this request type; empty array if no descendants
  def get_descendants
    descendants = []
    get_children.each do |child|
      descendants << child
      descendants.concat child.get_descendants
    end
    descendants
  end

  ##
  # Return true if the request type has child request types
  #
  # @return boolean: True if the request type has any direct children (equivalently if it is the parent of any
  #                  request types), False otherwise
  def has_children?
    RequestType.exists?(:parent_id => id)
  end
  
  ##
  # Return true if the request type has any descendant tickets (meaning itself or any of its descendant RQs are assigned to
  # any tickets), false otherwise
  #
  # @return boolean: True if the request type or any of its descendant request types are assigned to any ticket(s)
  def has_descendant_tickets?
    traverse_down {|rq| return true if !rq.tickets.empty? }
    return false
  end
  
  ##
  # Traverse the current request type and its children, listing the names (for testing purposes only for now)
  def walk
    traverse_down {|rq| puts rq.name }
  end 
  
  # --- CLASS METHODS --- #
  
  ##
  # Return the children RequestType objects of the specified parent_id in an array, ordered by
  # the RequestType name, or an empty array if the given parent id has no children
  def self.get_children_of(parent_id)
    RequestType.where({:parent_id => parent_id}).order("name")
  end
  
  ##
  # Return the active children RequestType objects of the specified parent_id in an array, ordered by
  # the RequestType name, or an empty array if the given parent id has no active children
  def self.get_active_children_of(parent_id)
    RequestType.where({:parent_id => parent_id, :active => true}).order("name")
  end
  
# --- PROTECTED INSTANCE METHODS --- #
protected
  # depth-first traversal of the children RQ tree, running the given block on each RQ, starting with the current RQ then
  # applying to each child recursively
  def traverse_down(&block)
    yield self
    get_children.each {|child| child.traverse_down &block}
  end

# --- PRIVATE INSTANCE METHODS --- #
private

  # Return true if the parent_id implies a cycle in the tree structure, which is BAD (cycle means the parent of this
  # request type is actually one of this request type's descendants or itself)
  def parent_causes_cycle
    traverse_down {|rq| return true if rq.id == parent_id}
    return false
  end
  
end
