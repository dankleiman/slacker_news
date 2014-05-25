require 'sinatra'
require 'csv'
require 'pry'
require 'uri'

def get_articles
  articles = []
  CSV.foreach('articles.csv', headers: true, header_converters: :symbol) do |article|
      articles << article.to_hash
  end
  articles
end

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
  existing_articles = get_articles
  # binding.pry
  existing_articles.each do |old_article|
    if old_article[:url] == (url)
      errors << "This article has already been submitted. Please submit something else."
    end
  end

  errors
end

get '/' do
  @articles = get_articles
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
      CSV.open("articles.csv", "a") { |csv| csv << [title, url, description]  }
      redirect '/'
  else
    erb :new
  end

end

 # query = params.map{|key, value| "#{key}=#{value}"}.join("&")
 #      redirect "/new?#{query}"
