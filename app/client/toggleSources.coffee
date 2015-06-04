
getSetting = (key) -> UserSettings.get "sourceEnabled_#{key}"
setSetting = (key, enabled) -> UserSettings.set "sourceEnabled_#{key}", enabled
Template.toggleSources.helpers
	sources: ->
		[
			(label: "Github", key: "github")
			(label: "Redmine", key: "redmine")
			(label: "Locations", key: "location")
			(label: "Calendar", key: "calendar")
				
		]
Template.toggleSources_source.helpers
	enabled: -> getSetting @key


Template.toggleSources_source.events
	'click': -> setSetting @key, not getSetting @key


