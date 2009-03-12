%w(cgi rubygems httparty springnote).each{|lib| require lib}
require File.dirname(__FILE__) + '/last_runtime'

class Delicious
  include HTTParty, LastRuntime
  base_uri "http://feeds.delicious.com/v2"
  
  def initialize(username, key)
    @username, @key = username, key
  end
  
  def inbox_posts
    Delicious.get("/json/inbox/#{@username}", :query => {:private => @key, :count => 15})
  end
  
  def format_post(post)
    homepage = "http://delicious.com/#{post['a']}"
    tags = post['t'].map do |t|
      %Q[<a href="#{homepage}/#{t}">#{t}</a>]
    end
    
    content  = %Q!<a href="#{post['u']}"><b>#{post['d']}</b></a>!
    content += " <br/> #{CGI.escapeHTML(post['n']).gsub(/\n/, ' <br/> ')}" if post['n'].to_s.strip.length > 0
    content += " \n (#{tags.join(" , ")})"                                 if tags.count > 0
    
    { 
      :name     => %Q!<img src="http://static.delicious.com/img/delicious.20.gif"/> #{post['a']}!,
      :homepage => homepage,
      :content  => "<p>#{content}</p>"
    }
  end
end


del = Delicious.new('hotruby', 'TDQLVkJuPugF4EHTglOcRYsbm_U-')
springnote = SpringnoteStore.new

del.with_last_runtime do |last, now|
  del.inbox_posts.
    sort{|x, y| y['dt'] <=> x['dt'] }.
    each do |post|
      next if last && last >= post['dt']
      
      ret = del.format_post(post)
      springnote.write ret[:name], ret[:homepage], ret[:content]
  end
end

