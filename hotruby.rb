%w(rubygems sinatra haml springnote).each{|lib| require lib}

before do
  @springnote = SpringnoteStore.new
end

get '/' do
  @items = @springnote.items(params[:page] || 1)
  haml :index
end

get '/items.atom' do
  header 'Content-Type' => 'application/atom+xml; charset=utf-8'

  @items = @springnote.entries(1)
  haml :atom, :layout => false
end

get '/items/:pid' do
  @items = [@springnote.item_by_id(params[:pid])]
  haml :index
end

get '/items/:pid/:itemid' do
  @item = @springnote.item_by_id(params[:pid])
  @contents = @item.extract_entry(params[:itemid])
  redirect "/items/#{params[:pid]}" if @contents.to_s.length <= 0
  haml :single
end

get '/search' do
  @items = @springnote.search(params[:q].to_s)
  haml :index
end

get '/write' do
  @author_name     = request.cookies['an'].to_s
  @author_homepage = request.cookies['ah'].to_s
  haml :write
end

post '/write' do
  throw(:halt, [401, 'go away!']) if params[:email].to_s.length > 0 || params[:contents].to_s.length > 0 # to prevent spams
  
  set_cookie 'an', params[:rref].to_s
  set_cookie 'ah', params[:rres].to_s
  
  @springnote.write params[:rref].to_s, params[:rres].to_s, params[:rree].to_s if params[:rref].to_s.length > 0 && params[:rree].to_s.length > 0
  redirect '/'
end

helpers do
  def sidebar
    @springnote.sidebar.source.to_s rescue ""
  end
end