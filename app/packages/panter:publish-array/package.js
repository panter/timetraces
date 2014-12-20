Package.describe({
  name: 'panter:publish-array',
  summary: ' /* Fill me in! */ ',
  version: '1.0.0',
  git: ' /* Fill me in! */ '
});

Package.onUse(function(api) {
  api.versionsFrom('1.0.1');
  api.use('coffeescript',['client','server']);
  api.addFiles('panter:publish-array.coffee');
});
