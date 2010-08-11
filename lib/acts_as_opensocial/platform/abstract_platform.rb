require 'net/http'
require 'net/https'
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
        
        method = (opt.delete(:method) || :get).to_s.upcase
        schema, port = opt.delete(:secure) ? ['https', 443] : ['http', 80]
        params = {
          :oauth_consumer_key => consumer_key,
          :oauth_nonce => Digest::MD5.hexdigest(rand.to_s),
          :oauth_signature_method => 'HMAC-SHA1',
          :oauth_timestamp => Time.now.to_i,
          :oauth_version => 1.0,
          :xoauth_requestor_id => owner_id
        }
        
        params[:oauth_token] = @auth[:oauth_token] unless batch_mode?
        
        params[:oauth_signature] = CGI.escape(make_signature("#{schema}://#{api_host}#{url}", method, params.merge(opt)))
        
        params_str = params.sort_by{|k, v| k.to_s}.map{|key, value| "#{key}=\"#{value}\""}.join(",")
        http = Net::HTTP.new(api_host, port)
        if port == 443
          http.use_ssl = true
          http.ca_file = '/etc/pki/tls/cert.pem'
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.verify_depth = 5
        end
        http.start do |con|
          url += '?' + opt.to_query if opt != {}
          method_class = "Net::HTTP::#{method.downcase.camelize}".constantize
          req = method_class.new(url)
          req.content_type = 'application/json'
          if post_data.present?
            req.body = post_data
            req.content_length = post_data.length
          end
          req['Authorization'] = "OAuth realm=\"\",#{params_str}"
          req['User-Agent'] = 'ruby-net-http/acts_as_opensocial'
          res = con.request(req)
        end
      end
      
      def prof(owner_id)
        res = send_request("/people/#{owner_id}/@self", owner_id)
        if res.code.to_i == 200
          JSON.parse(res.body)["entry"]
        end
      end
      
      def friends(owner_id)
        res = send_request("/people/#{owner_id}/@friends", owner_id)
      end
      
      def friend_list(owner_id, only_user = true, friends = [], index = 0)
        opt = {
          :count => 100,
          :startIndex => 100 * index + 1,
          :fields => 'nickname,id'
        }
        if only_user
          opt.update(:filterBy => 'hasApp', :filterOp => 'equals', :filterValue => 'true')
        end
        url = "/people/#{owner_id}/@friends"
        res = send_request(url, owner_id, opt)
        return friends unless res.code.to_i == 200
        json = JSON.parse(res.body)
        json['entry'].each do |friend|
          friends << {
            :opensocial_owner_id => friend['id'],
            :nickname => friend['nickname']
          }
        end
        return friends if json['totalResults'].to_i < 100 * (index + 1)
        friends(owner_id, only_user, friends, index + 1)
      end
      
      def activity(message, url)
        path = '/activities/@me/@self/@app'
        post_data = {
          :title => message,
          :url => url
        }.to_json
        res = send_request(path, @owner_id, {:method => :post}, post_data)
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
      
      def parse_auth(str = nil)
        if str
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
end
