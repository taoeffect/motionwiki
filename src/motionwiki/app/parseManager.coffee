define ['require', 'jquery', 'JSON', 'wiki/api'], (require, $, JSON, api)->
	
	parseData: (jqXHR, parseType, textStatus, [options]..., cb) ->
		if parseType == 'revisions'
			this.parseRevisions jqXHR, textStatus
		else

	parseRevisions: (jqXHR, textStatus, [options]..., cb) ->
		pagesJSON = $.parseJSON(JSON.stringify($.parseJSON(JSON.stringify(jqXHR, false, 100)).responseJSON.query.pages, false, 100))
		pagesJSONString = JSON.stringify(pagesJSON, false, 100)
		pagesJSONString = pagesJSONString.substring(35, pagesJSONString.length-1)
		pagesJSONString = "{\n" + pagesJSONString
		pageJSON = $.parseJSON(pagesJSONString)
		revisionsJSON = $.parseJSON(JSON.stringify(pageJSON.revisions), false, 100)
		number = 0;
		for revision in revisionsJSON
			revid = revision.revid
			parentid = revision.parentid
			timestamp = revision.timestamp
			$('<div>').css('color',if jqXHR.status < 300 then 'green' else 'red')
					.html(textStatus + ": <pre style='width:400'>" + JSON.stringify(revision, false, 100) + "</pre>")
					.appendTo('body > div')

