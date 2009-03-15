%w(cgi rubygems twitter activesupport springnote).each{|lib| require lib}
require File.dirname(__FILE__) + '/last_runtime'

config = YAML.load(File.read(File.dirname(__FILE__) + '/../datasources.yml'))['twitter']
twitter = Twitter::Base.new(config['id'], config['pw'])

module Twitter
  extend LastRuntime
  
  class Status
    def format_post
      content = text.gsub(/(http:\/\/[^\s]+)/) {|m| 
        %Q!<a href="#{m}">#{m}</a>!
      }.gsub(/@([-_A-Za-z0-9]+)/) {|m| 
        %Q!<a href="http://twitter.com/#{m[1..-1]}">#{m}</a>!
      }

      {
        :name     => %Q!<img src="#{user.profile_image_url}" width="20" height="20"/> #{user.name}!,
        :homepage => %Q!http://twitter.com/#{user.screen_name}!,
        :content  => "<p>#{content}</p>"
      }
    end
  end
end

springnote = SpringnoteStore.new
Twitter.with_last_runtime do |last, now|
  twitter.replies(:since => last || 7.days.ago).each do |s|
    ret = s.format_post
    springnote.write ret[:name], ret[:homepage], ret[:content]
  end
end