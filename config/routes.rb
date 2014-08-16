Rails.application.routes.draw do
  root to: 'casts#index'
  devise_for :users
  resources :users

  resources :casts
  get '/' => 'casts#index'
  get '/login' => 'casts#login'
  get '/castout/' => 'casts#castout'
  post '/submit' => 'casts#postcast'
  get '/submit' => 'casts#nth'
  get '/thanks' => 'casts#thanks'
end
