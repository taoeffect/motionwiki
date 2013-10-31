define ['require', 'jquery', 'JSON', 'wiki/api'], (require, $, JSON, api)->
	
	parseData: (jqXHR, parseType, textStatus, [options]..., cb) ->
		if parseType == 'compare'
			this.parseCompare jqXHR, textStatus
		else if parseType == 'diffs'
			this.parseDiffs jqXHR, textStatus

	parseDiffs: (jqXHR, textStatus, [options]..., cb) ->
		pagesJSON = $.parseJSON(JSON.stringify($.parseJSON(JSON.stringify(jqXHR, false, 100)).responseJSON.query.pages, false, 100))
		pagesJSONString = JSON.stringify(pagesJSON, false, 100)
		pagesJSONString = pagesJSONString.substring(35, pagesJSONString.length-1)
		pagesJSONString = "{\n" + pagesJSONString
		pageJSON = $.parseJSON(pagesJSONString)
		revisionsJSON = $.parseJSON(JSON.stringify(pageJSON.revisions), false, 100)
		number = 0;
		mod = 2

		allDiffs = []
		
		for revision in revisionsJSON
			_continue = true
			diffs = revision.diff
			diffsString = JSON.stringify(diffs, false, 100)
			diffsOriginal = JSON.stringify(diffs, false, 100)
			originalDiffs = []
			console.log "revision = #{diffsString} \n"
			

			
			while _continue == true
				
				diffsStart = diffsString.indexOf("diff-")
				if diffsStart > -1
					diffsString = diffsString.substring(diffsStart, diffsString.length - 1)
					#console.log "diffsString 1 = #{diffsString}"
					tagString = diffsString
					diffsStart = diffsString.indexOf("<div>")
					tagString = tagString.substring(0, diffsStart-1)
					#extract tag
					
					diffsString = diffsString.substring(diffsStart, diffsString.length - 1)

					tagString = tagString.split("").reverse().join("")
					tagStart = tagString.indexOf("<")
					tag = tagString.substring(0, tagStart)
					tag = tag.split("").reverse().join("")
					tagStart = tag.indexOf("=")
					tag = tag.substring(tagStart + 3, tag.length-2)
					#console.log "diffsString 2 = #{diffsString}"
					diffsEnd = diffsString.indexOf("</div>")
					diffsSub = diffsString.substring(5, diffsEnd)

					tagPair = [diffsSub, tag]
					originalDiffs.push tagPair
					difsString = diffsStart
					console.log "adding #{tagPair[1]}"
				else
					_continue = false


			#get added lines

			allDiffs.push originalDiffs

			
			$('<div>').css('color',if jqXHR.status < 300 then 'green' else 'red')
					#.html(textStatus + ": <pre style='width:400'>" + "char = '" + JSON.stringify(diffsNatural, false, 100) + "'" + "</pre>")
					.html(textStatus + ": <pre style='width:400'>" + JSON.stringify(diffsOriginal, false, 100) + "</pre>")
					.appendTo('body > div')

			#console.log "#{diffsNatural}"

		#_dmp = new diff_match_patch

	parseCompare: (jqXHR, textStatus, [options]..., cb) ->

		pagesJSON = $.parseJSON(JSON.stringify($.parseJSON(JSON.stringify(jqXHR, false, 100)).responseJSON.query.pages, false, 100))
		pagesJSONString = JSON.stringify(pagesJSON, false, 100)
		pagesJSONString = pagesJSONString.substring(35, pagesJSONString.length-1)
		pagesJSONString = "{\n" + pagesJSONString
		pageJSON = $.parseJSON(pagesJSONString)
		revisionsJSON = $.parseJSON(JSON.stringify(pageJSON.revisions), false, 100)
		number = 0;
		mod = 2

		revIDs = []
		diffs = []
		for revision in revisionsJSON

			
			originalDiffs = []
			revid = revision.revid
			parentid = revision.parentid
			timestamp = revision.timestamp

			revIDs.push revid

		index = 0
		while index < revIDs.length - 1
			revId1 = revIDs[index]
			revId2 = revIDs[index+1]
			api.compare revId1, revId2, (jqXHR, tetxStatus) ->
				#doStuff
				console.log "success"
			index++



			###

			_continue = true
			diffs = revision.diff
			diffsString = JSON.stringify(diffs, false, 100)
			diffsOriginal = JSON.stringify(diffs, false, 100)
			console.log "revision = #{diffsString} \n"
			

			
			while _continue == true
				
				diffsStart = diffsString.indexOf("diff-")
				if diffsStart > -1
					diffsString = diffsString.substring(diffsStart, diffsString.length - 1)
					#console.log "diffsString 1 = #{diffsString}"
					tagString = diffsString
					diffsStart = diffsString.indexOf("<div>")
					tagString = tagString.substring(0, diffsStart-1)
					#extract tag
					
					diffsString = diffsString.substring(diffsStart, diffsString.length - 1)

					tagString = tagString.split("").reverse().join("")
					tagStart = tagString.indexOf("<")
					tag = tagString.substring(0, tagStart)
					tag = tag.split("").reverse().join("")
					tagStart = tag.indexOf("=")
					tag = tag.substring(tagStart + 3, tag.length-2)
					#console.log "diffsString 2 = #{diffsString}"
					diffsEnd = diffsString.indexOf("</div>")
					diffsSub = diffsString.substring(5, diffsEnd)

					tagPair = [diffsSub, tag]
					originalDiffs.push tagPair
					difsString = diffsStart
					console.log "adding #{tagPair[1]}"
				else
					_continue = false


			#get added lines

			allDiffs.push originalDiffs

			
			$('<div>').css('color',if jqXHR.status < 300 then 'green' else 'red')
					#.html(textStatus + ": <pre style='width:400'>" + "char = '" + JSON.stringify(diffsNatural, false, 100) + "'" + "</pre>")
					.html(textStatus + ": <pre style='width:400'>" + JSON.stringify(diffsOriginal, false, 100) + "</pre>")
					.appendTo('body > div')

			#console.log "#{diffsNatural}"
		diffs = []
		revisionIndex = 0
		_dmp = new diff_match_patch

		myRev = allDiffs[0]
		myRev1 = myRev[2]
		myRev2 = myRev[3]
		myLine1 = myRev1[0]
		myLine2 = myRev2[0]
		result = _dmp.diff_main(myLine1, myLine2)

		console.log "result.length = #{result.length}"
		console.log "1 = #{result[0][1]}"
		console.log "2 = #{result[1][1]}"

		
		for revision in allDiffs
			size = revision.length
			console.log "size = #{size}"
			index = 0
			while index < size/2
				#result = diff_match_patch_uncompressed.diff_main((revision[index] * 2), (revision * 2) + 1)
				#dmp = new diff_match_patch_uncompressed.diff_match_patch
				#result = dmp.diff_main((revision[index] * 2), (revision * 2) + 1)
				if revisionIndex < allDiffs.length-1
					console.log "index = #{index}, revisionIndex = #{revisionIndex}"
					result = _dmp.diff_main((revision[index * 2]), (revision[index * 2 + 1]))
					diffs.push result
					index++
			revisionIndex++
			
		###




		
			


