%w(rubygems sinatra haml hpricot springnote).each{|lib| require lib}

before do
  @springnote = SpringnoteStore.new
end

get '/' do
  @items = @springnote.items(params[:page] || 1)
  haml :index
end

get '/items.atom' do
  header 'Content-Type' => 'application/atom+xml; charset=utf-8'
  
  @items = @springnote.items(1)[1..-1]
  haml :atom, :layout => false
end

get '/items/:pid/:itemid' do
  @item = @springnote.item_by_id(params[:pid])
  @contents = Hpricot(@item.source.to_s).search("#item_#{params[:itemid]}").html
  haml :single
end

get '/write' do
  haml :write
end

post '/write' do
  throw(:halt, [401, 'go away!']) if params[:email].to_s.length > 0 || params[:contents].to_s.length > 0 # to prevent spams
  
  @springnote.write params[:rref].to_s, params[:rres].to_s, params[:rree].to_s if params[:rref].to_s.length > 0 && params[:rree].to_s.length > 0
  redirect '/'
end

helpers do
  def sidebar
    @springnote.sidebar.source.to_s rescue ""
  end
end