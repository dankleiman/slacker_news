require 'sinatra'
require 'uri'
require 'pg'
require 'pry'



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
    conn.exec_params("INSERT INTO articles (link, title, description, username, submitted_at)
    VALUES ($1, $2, $3, $4, NOW());", [url, title, description, username])
  end
end

def save_comment(article_id, username, comment)
  db_connection do |conn|
    conn.exec_params("INSERT INTO comments (article_id, username, comment, submitted_at)
    VALUES ($1, $2, $3, NOW());", [article_id, username, comment])
  end
end


def check_url(url)
  db_connection do |conn|
    conn.exec_params("SELECT * FROM articles WHERE link = $1", [url])
  end
end

def get_comments(id)
  db_connection do |conn|
    conn.exec_params('SELECT articles.link, articles.title, comments.username, comments.submitted_at, comments.comment
      FROM articles
      JOIN comments ON articles.id = comments.article_id WHERE articles.id = $1', [id])
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
  #check for duplicate submissions
  if !check_url(url).to_a.empty?
    errors << "This article has already been submitted."
  end

  errors
end

def comment_errors(comment, username)
 errors = []

  if comment == ""
      errors << "Please enter a comment."
  end
  if username == ""
      errors << "Please enter a username."
  end

  errors
end


#########################
# ROUTES
#########################

get '/' do
  redirect '/articles'
end

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
  @errors = form_errors(title, url, description)
  if @errors.empty?
      save_article(url, title, description, username)
      redirect '/articles'
  else
    erb :'/articles/new'
  end

end

post '/articles/:article_id/comments' do
  article_id = params[:article_id]
  username = params[:username]
  comment = params[:comment]
  #when we implement validation, and the comment is empty, it sends to show page without other comment data
  @errors = []
  @errors = comment_errors(comment, username)
  binding.pry
  if @errors.empty?
    save_comment(article_id, username, comment)
    redirect "/articles/#{article_id}/comments"
  else
    erb :'comments/show'
  end
end

get '/articles/:article_id/comments' do
  @id = params[:article_id]
  @errors = []
  @comments = get_comments(@id)
  erb :'comments/show'
end

