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
  
  def get_text(text_id)
    text_id.map do |text_id|
      {"textId" => text_id, "data" => text_id, "status" => 0}
    end
  end
  
  def create_text(text)
    text
  end
end
