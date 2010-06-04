class DummyPlatform < OpenSocial::Platform::AbstractPlatform
  def initialize(controller = nil)
    super(controller)
  end
  
  def prof(owner_id)
    { "hasApp" => "true",
      "isOwner" => "true",
      "displayName" => "user_#{owner_id}",
      "nickname" => "user_#{owner_id}",
      "thumbnailUrl" => "http://example.com/thumbnail/#{owner_id}.jpg",
      "id" => "dummy:#{owner_id}",
      "updated" => "1945-08-06T08:15:00Z",
      "isViewer" => "true" }
  end
  
  def verify_signature
    true
  end
end
