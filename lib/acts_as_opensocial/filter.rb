class ActionController::Base
  attr_accessor :__opensocial_type
  def self.opensocial_filter(type = true)
    @@__opensocial_type = type
  end
  
  def opensocial_type
    @@__opensocial_type || false
  end
end
