module ActionView
  module Helpers
    module UrlHelper
      alias _orig_link_to link_to
      
      def link_to(*args, &block)
        case controller.opensocial_type
        when :mixi_mobile
          mixi_link_to(*args, &block)
        when true
          mixi_link_to(*args, &block)
        else
          _orig_link_to(*args, &block)
        end
      end
      
      def mixi_link_to(*args, &block)
        unless block_given?
          options = args.second || {}
          args[1] = mixi_url_for(options)
        end
        _orig_link_to(*args, &block)
      end  
      
      def mixi_url_for(options = {})
        require 'cgi'
        url = url_for(options)
        url = CGI.unescapeHTML(url)
        url = request.protocol + request.host_with_port + url if !url.match /^http/
        "?guid=ON&url=" + CGI.escape(url)
      end   
    end
  end
end
