require "sinatra"
require "pg"
require_relative "./app/models/article"

set :bind, '0.0.0.0'  # bind to all interfaces
set :views, File.join(File.dirname(__FILE__), "app", "views")

configure :development do
  set :db_config, { dbname: "news_aggregator_development" }
end

configure :test do
  set :db_config, { dbname: "news_aggregator_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get '/articles' do
  @articles = Article.all
  erb :index
end

get '/articles/new' do
  erb :new
end

post '/articles' do
  article = Article.new({ "title" => params['article_title'],
                          "url" => params['article_url'],
                          "description" => params['article_description']})
  if article.valid?
    article.save

    redirect '/articles'
  else
    @errors = article.errors
    @article_title = params['article_title']
    @article_url = params['article_url']
    @article_description = params['article_description']

    erb :new
  end
end
