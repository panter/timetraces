
getSetting = (type) -> UserSettings.get "sourceEnabled_#{type}"
setSetting = (type, enabled) -> UserSettings.set "sourceEnabled_#{type}", enabled
Template.toggleSources.helpers
	sources: ->
		[
			(label: "Github", type: "github")
			(label: "Redmine", type: "redmine")
			(label: "Locations", type: "location")
			(label: "Calendar", type: "calendar")
				
		]
Template.toggleSources_source.helpers
	enabled: -> getSetting @type


Template.toggleSources_source.events
	'click': -> setSetting @type, not getSetting @type


