class AppConfig
  def self.host(request_host='')
    APP_CONFIG[:app_host]
  end
end
