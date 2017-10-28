Rails.application.routes.draw do
  devise_for :employees
  root 'employees#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :employees
  resources :rest, :only => [] do
    collection do
      post 'login'
      get 'get_all'
      get 'get_emp'
      post 'add_emp'
      post 'update_emp'
      get 'delete_emp'
      post 'set_password'
    end
  end
end
