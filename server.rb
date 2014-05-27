require 'sinatra'
require 'csv'
require 'pry'
require 'uri'
require 'redis'
require 'json'

def get_connection
  if ENV.has_key?("REDISCLOUD_URL")
    Redis.new(url: ENV["REDISCLOUD_URL"])
  else
    Redis.new
  end
end

def find_articles
  redis = get_connection
  serialized_articles = redis.lrange("slacker:articles", 0, -1)

  articles = []

  serialized_articles.each do |article|
    articles << JSON.parse(article, symbolize_names: true)
  end

  articles
end

def save_article(url, title, description)
  article = { url: url, title: title, description: description }

  redis = get_connection
  redis.rpush("slacker:articles", article.to_json)
end

# def get_articles
#   articles = []
#   CSV.foreach('articles.csv', headers: true, header_converters: :symbol) do |article|
#       articles << article.to_hash
#   end
#   articles
# end

def form_errors(title, url, description)
  errors = []
  if title == ""
      errors << "Please enter a title."
  end
  #validate description
  if description == ""
      errors << "Please enter a description."
  end
  if description.length < 20
    errors << "Please enter a description of at least 20 characters."
  end
  #validate url
  if (url =~ URI::regexp) != 0
      errors << "Please enter a valid url."
  end
  existing_articles = find_articles
  # binding.pry
  existing_articles.each do |old_article|
    if old_article[:url] == (url)
      errors << "This article has already been submitted. Please submit something else."
    end
  end

  errors
end

get '/' do
  @articles = find_articles
  erb :index
end

get '/new' do
  @errors = []
  erb :new
end

post '/new' do
  title = params[:title]
  url = params[:url]
  description = params[:description]
  @errors = []
  #validate form entries
  @errors = form_errors(title, url, description)
  # binding.pry
  if @errors.empty? == true
    # binding.pry
      save_article(url, title, description)
      redirect '/'
  else
    erb :new
  end

end

 # query = params.map{|key, value| "#{key}=#{value}"}.join("&")
 #      redirect "/new?#{query}"
