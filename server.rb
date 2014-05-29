require 'sinatra'
require 'uri'
require 'pg'



#########################
# POSTGRES METHODS
#########################

configure :production do
  set :db_connection_info, {
    host: ENV['DB_HOST'],
    dbname:ENV['DB_DATABASE'],
    user:ENV['DB_USER'],
    password:ENV['DB_PASSWORD']
  }

end

configure :development do
  set :db_connection_info, {dbname: 'slacker_news'}
end

def db_connection
  begin
    connection = PG::Connection.open(settings.db_connection_info)
    yield(connection)
  ensure
    connection.close
  end
end

def find_articles
  db_connection do |conn|
    conn.exec("SELECT * FROM articles")
  end
end

def save_article(url, title, description, username)
  db_connection do |conn|
    conn.exec("INSERT INTO articles (url, title, description, username, submitted_at)
    VALUES ($1, $2, $3, $4, NOW());", [url, title, description, username])
  end
end

#########################
# OTHER METHODS
#########################

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

#########################
# ROUTES
#########################

get '/articles' do
  @articles = find_articles
  erb :'articles/index'
end

get '/articles/new' do
  @errors = []
  erb :'articles/new'
end

post '/articles/new' do
  title = params[:title]
  url = params[:url]
  description = params[:description]
  username = params[:username]
  @errors = []
  #validate form entries
  @errors = form_errors(title, url, description)
  # binding.pry
  if @errors.empty? == true
    # binding.pry
      save_article(url, title, description, username)
      redirect '/articles'
  else
    erb :'articles/new'
  end

end

