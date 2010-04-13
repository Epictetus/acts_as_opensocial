class ActionController::Base
  @__opensocial_type = false
  def self.opensocial_filter(type = true)
    @__opensocial_type = type
  end
  
  def opensocial_filter(type = true)
     @__opensocial_type = type
  end  
  
  def opensocial_type
    @__opensocial_type
  end
end
