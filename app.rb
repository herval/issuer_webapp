require 'rubygems'
require 'sinatra'
require 'oauth2' # ~> 0.5.0
require 'json'

def client
  OAuth2::Client.new(ENV['GITHUB_APP_ID'], ENV['GITHUB_APP_SECRET'],
                     :ssl => {:ca_file => '/etc/ssl/ca-bundle.pem'},
                     :site => 'https://api.github.com',
                     :authorize_url => 'https://github.com/login/oauth/authorize',
                     :token_url => 'https://github.com/login/oauth/access_token')
end

get "/" do
  %(<p><a href="/auth/github">Click here</a> to get an API token for <a href="https://github.com/herval/issuer">Issuer</a>.</p>)
end

get '/auth/github' do
  url = client.auth_code.authorize_url(:redirect_uri => redirect_uri, :scope => 'user,repo')
  puts "Redirecting to URL: #{url.inspect}"
  redirect url
end

get '/auth/github/callback' do
  puts params[:code]
  begin
    access_token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
    user = JSON.parse(access_token.get('/user').body)
    "<p>Your OAuth access token is: <b>#{access_token.token}</b> - copy+paste it for use on your Issuer installation and have fun!</p><p>Please note this token is PRIVATE and should not be shared with others!</p>"
  rescue OAuth2::Error => e
    %(<p>Outdated ?code=#{params[:code]}:</p><p>#{$!}</p><p><a href="/auth/github">Retry</a></p>)
  end
end

def redirect_uri(path = '/auth/github/callback', query = nil)
  uri = URI.parse(request.url)
  uri.path  = path
  uri.query = query
  uri.to_s
end