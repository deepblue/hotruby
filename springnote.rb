%w(springnote_client).each{|lib| require lib}

class SpringnoteStore
  APP_KEY = 'a7501dcb75519aec11a7049e62e3a0f533c265bb'
  ITEM_PER_PAGE = 7
  
  def initialize
    @note = Springnote(config('note_name'), :app_key => APP_KEY, :user_openid => config('user_openid'), :user_key => config('user_key'))
  end

  ##############################
  #### Public Methods

  def sidebar
    meta_page config('side_page')
  end
  
  def item_by_id(pid)
    @note.pages.find(pid)
  end
    
  def items(page = 1)
    s = (page-1)*ITEM_PER_PAGE
    e = s + ITEM_PER_PAGE
    pids = index_array[s...e].map{|v| v[1].to_i}.uniq
    [*@note.pages.find(*pids)].sort{|x, y| y.title <=> x.title}
  end
  
  def write(name, homepage, contents)
    target = today_page
    
    target.source = item_html(name, homepage, contents, target) + target.source.to_s
    target.save
  end
  
protected

  ##############################
  #### Config

  def self.config
    @config ||= YAML.load(File.read(File.dirname(__FILE__) + '/springnote.yml'))
  end
  
  def config(key)
    self.class.config[key]
  end  
  
  ##############################
  ### Meta Pages
  
  def meta_pages
    @meta_pages ||= @note.pages.find(config('side_page'), config('index_page'))
  end
  
  def meta_page(pid)
    meta_pages.select{|page| page.identifier == pid}[0]
  end
  
  def index_array
    indexes.to_a.sort{|x, y| y[0] <=> x[0]}
  end
  
  def indexes
    return @indexes if @indexes
    
    @indexes = {}
    meta_page(config('index_page')).source.to_s.
      scan(/<li>.*?<a.*?href=\"\/pages\/(\d+)\".*?>(.*?)<\/a>.*?<\/li>/mi).
      map do |m|
        @indexes[m[1].to_s] = m[0].to_i
      end
          
    @indexes
  end
  
  def update_index
    cont = index_array.map do |v|
      %Q[<li><a href="/pages/#{v[1]}">#{v[0]}</a>]
    end.join("\n")
            
    page = meta_page(config('index_page'))
    page.source = "<ul>#{cont}</ul>"
    page.save
  end
  
  
  ##############################
  ### Contents Pages
  
  def today_page
    key = Time.now.strftime('%Y-%m-%d')
    (indexes[key] && @note.pages.find(indexes[key])) || create_page(key)
  end
  
  def create_page(key)
    page = @note.pages.build(:title => key, :relation_is_part_of => config('index_page'))
    page.save
    
    @indexes[key] = page.identifier
    update_index
    
    page
  end
  
  def item_html(name, homepage, contents, target)
    now = Time.now
    idstr = now.to_i.to_s
    permlink = "/items/#{target.identifier}/#{idstr}"
    
    <<-END
      <div id="item_#{idstr}" class="item_container">
        <div class="item_body">#{contents}</div>
        <div class="item_meta">
          Posted by <a href="#{homepage}">#{name}</a> at <a href="#{permlink}"}>#{now.strftime("%H:%M")}</a> - 
          <a href="#{permlink}#disqus_thread">댓글</a>
        </div>
      </div><p>&nbsp;</p>
    END
  end
end