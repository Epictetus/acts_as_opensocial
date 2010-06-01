require 'net/http'
Net::HTTP.version_1_2

module OpenSocial
  module Platform
    class AbstractPlatform
      def initialize(controller = nil)
        if controller
          @auth = parse_auth(controller.request.headers["Authorization"])
          @owner_id = controller.params[:opensocial_owner_id]
        else
          @batch_mode = true
        end
      end 
      
      def batch_mode?
        @batch_mode || false
      end
      
     
      def api_host ; end
      def api_endpoint ; end
      def consumer_key ; end
      def consumer_secret ; end

      def make_signature(uri, method, params)
        require 'openssl'
        require 'base64'
        
        params.delete :oauth_signature
        msg = []
        msg << method
        msg << CGI.escape(uri)
        msg << CGI.escape(params.to_query)
        message = msg.join('&').chomp
        Base64.encode64(OpenSSL::HMAC::digest(OpenSSL::Digest::SHA1.new,
                                              consumer_secret + '&' + oauth_token_secret, message)).chomp
      end
      
      def send_request(path, owner_id, opt = {}, post_data = '')
        url = api_endpoint + path
        require 'digest/md5'
        
        method = opt.delete(:method) || 'GET'
        params = {
          :oauth_consumer_key => consumer_key,
          :oauth_nonce => Digest::MD5.hexdigest(rand.to_s),
          :oauth_signature_method => 'HMAC-SHA1',
          :oauth_timestamp => Time.now.to_i,
          :oauth_version => 1.0,
          :xoauth_requestor_id => owner_id
        }
        
        params[:oauth_token] = @auth[:oauth_token] unless batch_mode?
        
        params[:oauth_signature] = CGI.escape(make_signature("http://#{api_host}#{url}", method, params.merge(opt)))
        
        params_str = params.sort_by{|k, v| k.to_s}.map{|key, value| "#{key}=\"#{value}\""}.join(",")
        Net::HTTP.start(api_host, 80) do |http|
          url += '?' + opt.to_query if opt != {}
          if method == 'POST'
            req = Net::HTTP::Post.new(url)
            req.content_type = 'application/json'
            unless post_data.blank?
              req.body = post_data
              req.content_length = post_data.length
            end
          else
            req = Net::HTTP::Get.new(url)
          end
          req['Authorization'] = "OAuth #{params_str}"
          req['User-Agent'] = 'ruby-net-http/ctrl-plus'
          res = http.request(req)
        end
      end
      
      def prof(owner_id)
        send_request("/people/#{owner_id}/@self", owner_id)
      end
      
      def oauth_token_secret
        if !batch_mode? && @auth && @auth[:oauth_token_secret]
          @auth[:oauth_token_secret]
        else
          ''
        end
      end
      
      def verify_signature
        unless batch_mode?
          sig = {}
          sig[:oauth_consumer_key] = consumer_key
          sig[:oauth_nonce] = @auth[:oauth_nonce]
          sig[:oauth_timestamp] = @auth[:oauth_timestamp]
          sig[:oauth_token] = @auth[:oauth_token]
          sig[:oauth_signature_method] = @auth[:oauth_signature_method]
          sig[:oauth_version] = @auth[:oauth_version]
          sig[:xoauth_requestor_id] = @owner_id
          #sig.to_query
          #signature = @auth[:oauth_signature]
          #oauth_token_secret = @auth[:oauth_token_secret]
        end
      end
      
      def parse_auth(str)
        res = {}
        str.split(',').each do |p|
          x = p.split('=')
          res[x.first.strip.to_sym] = x.last.strip.gsub(/"/,'')
        end
        res
      end
    end
  end
end
