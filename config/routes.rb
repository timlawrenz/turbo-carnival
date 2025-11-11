Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Voting interface
  get "vote" => "image_votes#show", as: :vote
  post "vote" => "image_votes#vote"
  post "vote/reject/:id" => "image_votes#reject", as: :reject_vote
  
  # Winners gallery
  get "winners" => "winners#index", as: :winners

  # Image serving
  get "images/:id" => "images#show", as: :candidate_image

  # Defines the root path route ("/")
  root "image_votes#show"
end
