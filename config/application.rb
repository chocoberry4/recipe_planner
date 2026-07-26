require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RecipePlanner
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Cookie-based sessions are used for authentication (see
    # docs/adr/0001-cookie-session-auth.md), so the session/cookie middleware
    # that API-only mode skips by default needs to be added back explicitly.
    # `secure` was `Rails.env.production?`, which marks the cookie Secure any
    # time RAILS_ENV=production - regardless of whether real TLS actually
    # terminates in front of the app. Neither GCP (no domain/cert yet) nor
    # Unraid (plain HTTP on the LAN) do, so browsers silently refused to
    # store/send back a Secure cookie over those plain-HTTP connections,
    # breaking login/signup right after the cookie was set. Switch back to
    # tying this to production once a real domain + TLS cert sits in front.
    config.session_store :cookie_store,
      key: "_recipe_planner_session",
      same_site: :lax,
      secure: false
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options

    # Rails' default (5 minutes) means every ActiveStorage blob/variant URL's
    # signed redirect - and the extra round-trip that goes with it - has to
    # be re-resolved that often even though the underlying file never
    # changes (blobs are content-addressed; a different image is a different
    # blob/URL entirely). Recipe photos aren't sensitive content, so a long
    # expiry trades a bit of URL-sharing precision for far fewer of those
    # redirects in the common case of browsing recipes repeatedly.
    config.active_storage.service_urls_expire_in = 1.day
  end
end
