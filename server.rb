require 'rubygems'
require 'net/http'
require 'json'
require 'sinatra'
require './question'

@@tutors = {}

post '/sign_in' do
  return token_for(params[:email]) if authenticate?(params)
  return 400
end

get '/tutor/:email/notification' do
  content_type :json
  email, token = params[:email], params[:token]
  return 401 unless allowed? email, token
  update_session email
  notify email
end

get '/tutor' do
  content_type :json
  invalidate_sessions
  available_tutors
end

post '/tutor/:email/notification' do
  email = params[:email]
  default_hash_for email
  add_notification params
  201
end


private

def authenticate?(params)
  email = params[:email]
  password = params[:password]
  response = Net::HTTP.get_response URI "http://www.rayku.com/loginchecker.php?usr=#{email}&pwd=#{password}"
  response.code ==  '200'
end

def token_for(email)
  token = rand(36**8).to_s(36)
  default_hash_for email
  @@tutors[email][:token] = token
  token
end

def notify(user)
  default_hash_for user
  questions = @@tutors[user][:questions]
  questions.delete_at(0).to_json unless questions.empty?
end

def allowed?(email, token)
  return @@tutors[email][:token] == token if @@tutors.include? email
  false
end

def default_hash_for(email)
  @@tutors[email] =  { :token => '', :questions => [], :expires => in_2_minutes } unless @@tutors.include? email
end

def add_notification params
  @@tutors[params[:email]][:questions] << Question.new(:body => params[:body], :time_left => params[:timeLeft].to_i, :grade => params[:grade], :link => params[:link])
end

def available_tutors
  @@tutors.keys.to_json
end

def update_session email
  @@tutors[email][:expires] = in_2_minutes
end

def in_2_minutes
  Time.now + 60 * 2
end

def invalidate_sessions
  @@tutors = @@tutors.reject do |email, info|
    info[:expires] < Time.now
  end
end
