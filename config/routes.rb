Rails.application.routes.draw do
  namespace :v1 do
    resources :book do
      collection do
        get 'question'
      end
    end
  end
end
