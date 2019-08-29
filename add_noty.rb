run 'yarn add noty '

inject_into_file 'app/javascript/packs/application.js', after: 'require("channels' do <<-JS
  
  window.Noty = require("noty")
JS

inject_into_file 'app/javascript/packs/src/application.scss'
do <<-TXT
  @import '~noty/lib/noty';
  @import '~noty/lib/themes/sunset';
TXT

run 'app/views/shared/_flashes.slim'

file 'app/views/shared/_flashes.slim', <<-SLIM
- unless flash.empty?
  - flash.each do |key, value|
    - type = key.to_s.gsub('alert', 'error').gsub('notice', 'success')
    javascript:
      new Noty({
        layout: 'bottomRight',
        timeout: '3000',
        theme: 'sunset',
        text: "#{value}",
        type: "#{type}",
      }).show();
SLIM