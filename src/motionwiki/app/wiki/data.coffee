define [], () ->

	parsedWikiTextReturn = false
	diffTextReturn = false

	setParsedWikiTextReturnToTrue: ->
		parsedWikiTextReturn = true
		console.log "parsedWikiTextReturn == true"
		#diffArticle

	setDiffTextReturnToTrue: ->
		diffTextReturn = true
		console.log "diffTextReturn == true"
		#@diffArticle

	setParsedWikiTextReturnToFalse: ->
		parsedWikiTextReturn = false

	setDiffTextReturnToFalse: ->
		diffTextReturn = false

	diffArticle: ->
		if parsedWikiTextReturn == true and diffTextReturn == true
			console.log "diffArticle true"
		else
			console.log "diffArticle false"

	
