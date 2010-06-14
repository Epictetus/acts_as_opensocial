module OpenSocial
  module TextApi
    module ActiveRecordExtend
      module ActMethods
        def self.extended(base)
          base.send(:extend, ClassMethods)
          base.send(:include, InstanceMethods)
        end
        
        def text_api(key)
          create_text_association(key)
        end
      end
      
      module ClassMethods
        def create_text_association(key)
          text_id_list << key
          define_method("#{key}_object") do
            text_api_instances[key] ||= TextApi::Text.new(self, key, read_attribute("#{key}_text_id"))
          end
          
          define_method("#{key}") do
            send("#{key}_object").text
          end
          
          define_method("#{key}=") do |param|
            send("#{key}_object").set(param)
          end
        end

        def text_id_list
          @text_id_list ||= []
        end
      end
      
      module InstanceMethods
        private
        def text_api_instances
          @text_api_instances ||= {}
        end
      end
    end
    
    def self.fetch(opensocial, objects)
      objects = [objects] unless objects.is_a?(Array)
      list = objects.map{|object|
        object.class.text_id_list.map do |key|
          object.send("#{key}_object")
        end
      }.flatten.uniq
      text_id_list = list.map{|x|
        x.text_id
      }.compact
      text_list = opensocial.get_text(text_id_list)
      
      text_list.each do |text|
        list.find{|x| x.text_id == text["textId"]}.load(text)
      end
      objects
    end
    
    class Text
      attr_accessor :obj, :key, :text_id, :text, :old_text, :status
      def initialize(obj, key, text_id = nil)
        self.obj = obj
        self.key = key
        self.text_id = text_id
      end
      
      def set(str)
        self.text = str
      end
      
      def new_record?
        text_id.blank?
      end
      
      def load(data)
        self.old_text = data["data"]
        self.text = data["data"] if text.blank?
        self.status = data["status"]
        @load = true
      end
      
      def load?
        @load ||= false
      end
      
      def save
        
      end
    end
  end
end
