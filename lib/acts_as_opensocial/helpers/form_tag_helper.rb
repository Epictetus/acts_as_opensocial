module ActionView
  module Helpers
    module FormTagHelper      
      def form_tag_html(html_options)
        extra_tags = extra_tags_for_form(html_options) 
        case opensocial = html_options.delete('os')
          when :mixi_mobile
          extra_tags += mixi_tags_for_form(html_options)
          html_options['action'] = '?guid=ON'
        end
        tag(:form, html_options, true) + extra_tags
      end
      
      def mixi_tags_for_form(html_options)
        require 'cgi'
        path = request.protocol + request.host_with_port + html_options['action']
        tag(:input, :type => 'hidden', :name => 'url', :value => path)
      end
    end
  end
end
