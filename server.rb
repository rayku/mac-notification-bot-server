require 'rubygems'
require 'net/http'
require 'json'
require 'sinatra'
require './question'

@@tutors = {}

get '/download/update.xml' do
  content_type :xml
  send_file File.join('public', 'update.xml')
end

get '/download/rayku.*' do
  send_file File.join('public', "notificationBot.#{params[:splat][0]}")
end

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

  tutors = available_tutors
  return tutors.to_json unless params[:status]

  tutors.reject { |tutor|
    tutor[:status] != params[:status]
  }.to_json
end

get '/status/:email' do
  content_type :json
  invalidate_sessions
  get_status params[:email]
end

post '/tutor/:email/ping' do
  update_status params[:email], params[:status]
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
  response = Net::HTTP.get_response URI "http://www.rayku.com/api.php/auth/checkLogin?email=#{email}&password=#{password}"
  response.body == 'OK'
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
  @@tutors[email] =  {:status => 'available', :token => '', :questions => [], :expires => in_2_minutes } unless @@tutors.include? email
end

def add_notification params
  @@tutors[params[:email]][:questions] << Question.new(:body => params[:body], :time_left => params[:timeLeft].to_i, :grade => params[:grade], :link => params[:link])
end

def available_tutors
  @@tutors.map do |email, info|
    {:email => email, :status => info[:status]}
  end
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

def update_status email, status
  @@tutors[email][:status] = status
end

def get_status email
  retur @@tutors[email][:status] if @@tutors.include? email
  false
end
