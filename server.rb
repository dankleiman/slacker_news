require 'sinatra'
require 'csv'
require 'pry'

def get_articles
  articles = []
  CSV.foreach('articles.csv', headers: true, header_converters: :symbol) do |article|
      articles << article.to_hash
  end
  articles
end

get '/' do
  @articles = get_articles
  erb :index
end

get '/new' do
  erb :new
end

post '/' do
  title = params[:title]
  url = params[:url]
  description = params[:description]

  CSV.open("articles.csv", "a") { |csv| csv << [title, url, description]  }
  redirect "/"
end

