require 'spaceship'

Spaceship::ConnectAPI.login('mattioli.simone.10@gmail.com')
app = Spaceship::ConnectAPI::App.find('com.simo.pingpong')
version = app.get_edit_app_store_version
puts "Edit Version Localizations:"
version.get_app_store_version_localizations.each do |loc|
  puts loc.locale
end
