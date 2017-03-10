require 'pg'
require 'pry'
require 'uri'
require 'sinatra'


class Article
  attr_reader :title, :url, :description, :errors

  def initialize(article = {})
    @title = article["title"]
    @url = article["url"]
    @description = article["description"]
    @errors = []
  end

  def db_connection
    begin
      connection = PG.connect(Sinatra::Application.db_config)
      yield(connection)
    ensure
      connection.close
    end
  end

  def valid?
    valid = true
    if [@title,@url,@description].any? { |attr| attr == "" }
      @errors << "Please fill in all fields"
      valid = false
    end
    if !@url.start_with?("http") && @url != ""
      @errors << "Invalid URL"
      valid = false
    end
    if duplicate?
      @errors << "Article with same url already submitted"
      valid = false
    end
    if @description != "" && @description.length < 20
      @errors << "Description must be at least 20 characters long"
      valid = false
    end
    valid
  end

  def duplicate?
    db_connection do |conn|
      articles = conn.exec("SELECT title, url, description FROM articles")
      articles.to_a.each do |article|
        if @url == article["url"]
          return true
        end
      end
    end
    return false
  end

  def save
    if valid?
      db_connection do |conn|
        conn.exec_params("INSERT INTO articles (title,url,description) VALUES($1,$2,$3)", [@title,@url,@description])
      end
    return true
    end
    return false
  end

  def self.all
    @articles = []
    db_connection do |conn|
      articles = conn.exec("SELECT title, url, description FROM articles")
      articles.to_a.each do |article|
        @articles << new(article)
      end
    end
    @articles
  end

end
