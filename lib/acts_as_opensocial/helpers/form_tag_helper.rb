module ActionView
  module Helpers
    module FormTagHelper      
      def form_tag_html(html_options)
        extra_tags = extra_tags_for_form(html_options)
        case controller.opensocial_type
        when :mixi_mobile
          extra_tags += mixi_tags_for_form(html_options)
          html_options['action'] = '?guid=ON'
        when true
          extra_tags += mixi_tags_for_form(html_options)
          html_options['action'] = '?guid=ON'
        end
        extra_tags.html_safe! if extra_tags.respond_to?(:html_safe!)
        extra_tags = extra_tags.html_safe if extra_tags.respond_to?(:html_safe)
        
        tag(:form, html_options, true) + extra_tags
      end
      
      def mixi_tags_for_form(html_options)
        require 'cgi'
        if !html_options['action'].match(/^http:\/\//)
          path = request.protocol + 
            request.host_with_port + 
            html_options['action']
        else
          path = html_options['action']
        end
        tag(:input, :type => 'hidden', :name => 'url', :value => path) +
          tag(:input, :type => 'hidden', :name => 'guid', :value => 'ON')
      end
    end
  end
end
