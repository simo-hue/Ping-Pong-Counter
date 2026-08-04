require 'spaceship'

Spaceship::ConnectAPI.login('mattioli.simone.10@gmail.com')
app = Spaceship::ConnectAPI::App.find('com.simo.pingpong')

puts "Fetching App Info Localizations (Names)..."
app.fetch_edit_app_info.get_app_info_localizations.each do |loc|
  puts "#{loc.locale}: #{loc.name}"
end
