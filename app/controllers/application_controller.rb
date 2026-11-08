class ApplicationController < ActionController::Base
  # The benchmarks hit these endpoints with curl/k6, so we do not restrict browsers
  # (Rails' generated `allow_browser versions: :modern` would answer 406 to them).
end
