Template.modal.rendered = ->
	$modal = @$(".modal").modal show: no
	$modal.on "show.bs.modal", ->
		hash = @id
		window.location.hash = hash
		closeOnHash = ->
			unless window.location.hash is "##{hash}"
				$modal.modal "hide"
				$(window).off "hashchange", closeOnHash
		$(window).on "hashchange", closeOnHash

	$modal.on "hidden.bs.modal", ->
		history.pushState '', document.title, window.location.pathname

Template.modal.events
	'click button[type="submit"]': (event, template) ->
		template.$("form").submit()
Template.modal_footer_button.helpers
	type: -> @type ? "button"
