# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# The Vue frontend is served by the Vite dev server on a different port than
# the Rails API in development, so cookie-session auth requires CORS with
# credentials enabled for that origin (see docs/adr/0001-cookie-session-auth.md).
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:3036"

    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: true
  end
end
