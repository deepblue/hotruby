%w(hpricot springnote_client).each{|lib| require lib}
     
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
    
  def entries(page = 1)
    items(page).map{|page| page.entries}.flatten
  end
  
  def search(query)
    []
  end
    
  def write(name, homepage, contents)
    today_page.append_entry(name, homepage, contents)
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
  
  def index_page
    meta_page(config('index_page'))
  end
    
  def index_array
    index_hash.to_a.sort{|x, y| y[0] <=> x[0]}
  end
  
  def index_hash
    @index_hash ||= index_page.to_index_hash
  end
  
  def update_index            
    page = index_page.save_index(index_array)
  end
  
  
  ##############################
  ### Contents Pages
  
  def today_page
    key = Time.now.strftime('%Y-%m-%d')
    (index_hash[key] && @note.pages.find(index_hash[key])) || create_page(key)
  end
  
  def create_page(key)
    page = @note.pages.build(:title => key, :relation_is_part_of => config('index_page'))
    page.save
    
    @index_hash[key] = page.identifier
    update_index
    
    page
  end
end


class Springnote::Page
  def parsed
    @parsed ||= Hpricot(self.source.to_s)
  end
  
  ################################
  # For Entry Page
  
  def extract_entry(entry_id)
    parsed.search("#item_#{entry_id}").html
  end
  
  def entries
    parsed.search('.item_container').map do |container|
      {
        :identifier => container.attributes['id'].split('_')[1].to_s,
        :title =>  container.search('.item_meta').text.split(' - ')[0].to_s,
        :source => container.search('.item_body').html,
        :page_id => self.identifier
      }
    end
  end
  
  def append_entry(name, homepage, contents)
    self.source = entry_html(name, homepage, contents) + self.source.to_s
    save
  end
  
  ################################
  # For Index Page  
  
  def save_index(ary)
    self.source = index_html(ary)
    save
  end
  
  def to_index_hash
    ret = {}
    self.source.to_s.
      scan(/<li>.*?<a.*?href=\"\/pages\/(\d+)\".*?>(.*?)<\/a>.*?<\/li>/mi).
      map do |m|
        ret[m[1].to_s] = m[0].to_i
      end
    ret
  end
  
protected
  def entry_html(name, homepage, contents)
    now = Time.now
    idstr = now.to_i.to_s
    permlink = "/items/#{self.identifier}/#{idstr}"
  
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
  
  def index_html(ary)
    cont = ary.map do |v|
      %Q[<li><a href="/pages/#{v[1]}">#{v[0]}</a>]
    end.join("\n")
            
    "<ul>#{cont}</ul>"
  end
end
