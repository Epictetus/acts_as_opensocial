require 'acts_as_opensocial/platform/abstract_platform'
require 'acts_as_opensocial/platform/dummy_platform'
require 'acts_as_opensocial/platform/text_api'

ActiveRecord::Base.send(:extend, OpenSocial::TextApi::ActiveRecordExtend::ActMethos)
#require 'acts_as_opensocial/platform/mixi'
#require 'acts_as_opensocial/platform/gree'
