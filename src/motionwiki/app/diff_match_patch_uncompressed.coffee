###
Diff Match and Patch

Copyright 2006 Google Inc.
http://code.google.com/p/google-diff-match-patch/

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
###

###
@fileoverview Computes the difference between two texts to create a patch.
Applies the patch onto another text, allowing for errors.
@author fraser@google.com (Neil Fraser)
###

###
Class containing the diff, match and patch methods.
@constructor
###
diff_match_patch = ->
  
  # Defaults.
  # Redefine these in your program to override the defaults.
  
  # Number of seconds to map a diff before giving up (0 for infinity).
  @Diff_Timeout = 1.0
  
  # Cost of an empty edit operation in terms of edit characters.
  @Diff_EditCost = 4
  
  # At what point is no match declared (0.0 = perfection, 1.0 = very loose).
  @Match_Threshold = 0.5
  
  # How far to search for a match (0 = exact location, 1000+ = broad match).
  # A match this many characters away from the expected location will add
  # 1.0 to the score (0.0 is a perfect match).
  @Match_Distance = 1000
  
  # When deleting a large block of text (over ~64 characters), how close do
  # the contents have to be to match the expected contents. (0.0 = perfection,
  # 1.0 = very loose).  Note that Match_Threshold controls how closely the
  # end points of a delete need to match.
  @Patch_DeleteThreshold = 0.5
  
  # Chunk size for context length.
  @Patch_Margin = 4
  
  # The number of bits in an int.
  @Match_MaxBits = 32

#  DIFF FUNCTIONS

###
The data structure representing a diff is an array of tuples:
[[DIFF_DELETE, 'Hello'], [DIFF_INSERT, 'Goodbye'], [DIFF_EQUAL, ' world.']]
which means: delete 'Hello', add 'Goodbye' and keep ' world.'
###
DIFF_DELETE = -1
DIFF_INSERT = 1
DIFF_EQUAL = 0

###
@typedef {{0: number, 1: string}}
###
diff_match_patch.Diff

###
Find the differences between two texts.  Simplifies the problem by stripping
any common prefix or suffix off the texts before diffing.
@param {string} text1 Old string to be diffed.
@param {string} text2 New string to be diffed.
@param {boolean=} opt_checklines Optional speedup flag. If present and false,
then don't run a line-level diff first to identify the changed areas.
Defaults to true, which does a faster, slightly less optimal diff.
@param {number} opt_deadline Optional time when the diff should be complete
by.  Used internally for recursive calls.  Users should set DiffTimeout
instead.
@return {!Array.<!diff_match_patch.Diff>} Array of diff tuples.
###
diff_match_patch::diff_main = (text1, text2, opt_checklines, opt_deadline) ->
  
  # Set a deadline by which time the diff must be complete.
  if typeof opt_deadline is "undefined"
    if @Diff_Timeout <= 0
      opt_deadline = Number.MAX_VALUE
    else
      opt_deadline = (new Date).getTime() + @Diff_Timeout * 1000
  deadline = opt_deadline
  
  # Check for null inputs.
  throw new Error("Null input. (diff_main)")  if not text1? or not text2?
  
  # Check for equality (speedup).
  if text1 is text2
    return [[DIFF_EQUAL, text1]]  if text1
    return []
  opt_checklines = true  if typeof opt_checklines is "undefined"
  checklines = opt_checklines
  
  # Trim off common prefix (speedup).
  commonlength = @diff_commonPrefix(text1, text2)
  commonprefix = text1.substring(0, commonlength)
  text1 = text1.substring(commonlength)
  text2 = text2.substring(commonlength)
  
  # Trim off common suffix (speedup).
  commonlength = @diff_commonSuffix(text1, text2)
  commonsuffix = text1.substring(text1.length - commonlength)
  text1 = text1.substring(0, text1.length - commonlength)
  text2 = text2.substring(0, text2.length - commonlength)
  
  # Compute the diff on the middle block.
  diffs = @diff_compute_(text1, text2, checklines, deadline)
  
  # Restore the prefix and suffix.
  diffs.unshift [DIFF_EQUAL, commonprefix]  if commonprefix
  diffs.push [DIFF_EQUAL, commonsuffix]  if commonsuffix
  @diff_cleanupMerge diffs
  diffs


###
Find the differences between two texts.  Assumes that the texts do not
have any common prefix or suffix.
@param {string} text1 Old string to be diffed.
@param {string} text2 New string to be diffed.
@param {boolean} checklines Speedup flag.  If false, then don't run a
line-level diff first to identify the changed areas.
If true, then run a faster, slightly less optimal diff.
@param {number} deadline Time when the diff should be complete by.
@return {!Array.<!diff_match_patch.Diff>} Array of diff tuples.
@private
###
diff_match_patch::diff_compute_ = (text1, text2, checklines, deadline) ->
  diffs = undefined
  
  # Just add some text (speedup).
  return [[DIFF_INSERT, text2]]  unless text1
  
  # Just delete some text (speedup).
  return [[DIFF_DELETE, text1]]  unless text2
  longtext = (if text1.length > text2.length then text1 else text2)
  shorttext = (if text1.length > text2.length then text2 else text1)
  i = longtext.indexOf(shorttext)
  unless i is -1
    
    # Shorter text is inside the longer text (speedup).
    diffs = [[DIFF_INSERT, longtext.substring(0, i)], [DIFF_EQUAL, shorttext], [DIFF_INSERT, longtext.substring(i + shorttext.length)]]
    
    # Swap insertions for deletions if diff is reversed.
    diffs[0][0] = diffs[2][0] = DIFF_DELETE  if text1.length > text2.length
    return diffs
  
  # Single character string.
  # After the previous speedup, the character can't be an equality.
  return [[DIFF_DELETE, text1], [DIFF_INSERT, text2]]  if shorttext.length is 1
  
  # Check to see if the problem can be split in two.
  hm = @diff_halfMatch_(text1, text2)
  if hm
    
    # A half-match was found, sort out the return data.
    text1_a = hm[0]
    text1_b = hm[1]
    text2_a = hm[2]
    text2_b = hm[3]
    mid_common = hm[4]
    
    # Send both pairs off for separate processing.
    diffs_a = @diff_main(text1_a, text2_a, checklines, deadline)
    diffs_b = @diff_main(text1_b, text2_b, checklines, deadline)
    
    # Merge the results.
    return diffs_a.concat([[DIFF_EQUAL, mid_common]], diffs_b)
  return @diff_lineMode_(text1, text2, deadline)  if checklines and text1.length > 100 and text2.length > 100
  @diff_bisect_ text1, text2, deadline


###
Do a quick line-level diff on both strings, then rediff the parts for
greater accuracy.
This speedup can produce non-minimal diffs.
@param {string} text1 Old string to be diffed.
@param {string} text2 New string to be diffed.
@param {number} deadline Time when the diff should be complete by.
@return {!Array.<!diff_match_patch.Diff>} Array of diff tuples.
@private
###
diff_match_patch::diff_lineMode_ = (text1, text2, deadline) ->
  
  # Scan the text on a line-by-line basis first.
  a = @diff_linesToChars_(text1, text2)
  text1 = a.chars1
  text2 = a.chars2
  linearray = a.lineArray
  diffs = @diff_main(text1, text2, false, deadline)
  
  # Convert the diff back to original text.
  @diff_charsToLines_ diffs, linearray
  
  # Eliminate freak matches (e.g. blank lines)
  @diff_cleanupSemantic diffs
  
  # Rediff any replacement blocks, this time character-by-character.
  # Add a dummy entry at the end.
  diffs.push [DIFF_EQUAL, ""]
  pointer = 0
  count_delete = 0
  count_insert = 0
  text_delete = ""
  text_insert = ""
  while pointer < diffs.length
    switch diffs[pointer][0]
      when DIFF_INSERT
        count_insert++
        text_insert += diffs[pointer][1]
      when DIFF_DELETE
        count_delete++
        text_delete += diffs[pointer][1]
      when DIFF_EQUAL
        
        # Upon reaching an equality, check for prior redundancies.
        if count_delete >= 1 and count_insert >= 1
          
          # Delete the offending records and add the merged ones.
          diffs.splice pointer - count_delete - count_insert, count_delete + count_insert
          pointer = pointer - count_delete - count_insert
          a = @diff_main(text_delete, text_insert, false, deadline)
          j = a.length - 1

          while j >= 0
            diffs.splice pointer, 0, a[j]
            j--
          pointer = pointer + a.length
        count_insert = 0
        count_delete = 0
        text_delete = ""
        text_insert = ""
    pointer++
  diffs.pop() # Remove the dummy entry at the end.
  diffs


###
Find the 'middle snake' of a diff, split the problem in two
and return the recursively constructed diff.
See Myers 1986 paper: An O(ND) Difference Algorithm and Its Variations.
@param {string} text1 Old string to be diffed.
@param {string} text2 New string to be diffed.
@param {number} deadline Time at which to bail if not yet complete.
@return {!Array.<!diff_match_patch.Diff>} Array of diff tuples.
@private
###
diff_match_patch::diff_bisect_ = (text1, text2, deadline) ->
  
  # Cache the text lengths to prevent multiple calls.
  text1_length = text1.length
  text2_length = text2.length
  max_d = Math.ceil((text1_length + text2_length) / 2)
  v_offset = max_d
  v_length = 2 * max_d
  v1 = new Array(v_length)
  v2 = new Array(v_length)
  
  # Setting all elements to -1 is faster in Chrome & Firefox than mixing
  # integers and undefined.
  x = 0

  while x < v_length
    v1[x] = -1
    v2[x] = -1
    x++
  v1[v_offset + 1] = 0
  v2[v_offset + 1] = 0
  delta = text1_length - text2_length
  
  # If the total number of characters is odd, then the front path will collide
  # with the reverse path.
  front = (delta % 2 isnt 0)
  
  # Offsets for start and end of k loop.
  # Prevents mapping of space beyond the grid.
  k1start = 0
  k1end = 0
  k2start = 0
  k2end = 0
  d = 0

  while d < max_d
    
    # Bail out if deadline is reached.
    break  if (new Date()).getTime() > deadline
    
    # Walk the front path one step.
    k1 = -d + k1start

    while k1 <= d - k1end
      k1_offset = v_offset + k1
      x1 = undefined
      if k1 is -d or (k1 isnt d and v1[k1_offset - 1] < v1[k1_offset + 1])
        x1 = v1[k1_offset + 1]
      else
        x1 = v1[k1_offset - 1] + 1
      y1 = x1 - k1
      while x1 < text1_length and y1 < text2_length and text1.charAt(x1) is text2.charAt(y1)
        x1++
        y1++
      v1[k1_offset] = x1
      if x1 > text1_length
        
        # Ran off the right of the graph.
        k1end += 2
      else if y1 > text2_length
        
        # Ran off the bottom of the graph.
        k1start += 2
      else if front
        k2_offset = v_offset + delta - k1
        if k2_offset >= 0 and k2_offset < v_length and v2[k2_offset] isnt -1
          
          # Mirror x2 onto top-left coordinate system.
          x2 = text1_length - v2[k2_offset]
          
          # Overlap detected.
          return @diff_bisectSplit_(text1, text2, x1, y1, deadline)  if x1 >= x2
      k1 += 2
    
    # Walk the reverse path one step.
    k2 = -d + k2start

    while k2 <= d - k2end
      k2_offset = v_offset + k2
      x2 = undefined
      if k2 is -d or (k2 isnt d and v2[k2_offset - 1] < v2[k2_offset + 1])
        x2 = v2[k2_offset + 1]
      else
        x2 = v2[k2_offset - 1] + 1
      y2 = x2 - k2
      while x2 < text1_length and y2 < text2_length and text1.charAt(text1_length - x2 - 1) is text2.charAt(text2_length - y2 - 1)
        x2++
        y2++
      v2[k2_offset] = x2
      if x2 > text1_length
        
        # Ran off the left of the graph.
        k2end += 2
      else if y2 > text2_length
        
        # Ran off the top of the graph.
        k2start += 2
      else unless front
        k1_offset = v_offset + delta - k2
        if k1_offset >= 0 and k1_offset < v_length and v1[k1_offset] isnt -1
          x1 = v1[k1_offset]
          y1 = v_offset + x1 - k1_offset
          
          # Mirror x2 onto top-left coordinate system.
          x2 = text1_length - x2
          
          # Overlap detected.
          return @diff_bisectSplit_(text1, text2, x1, y1, deadline)  if x1 >= x2
      k2 += 2
    d++
  
  # Diff took too long and hit the deadline or
  # number of diffs equals number of characters, no commonality at all.
  [[DIFF_DELETE, text1], [DIFF_INSERT, text2]]


###
Given the location of the 'middle snake', split the diff in two parts
and recurse.
@param {string} text1 Old string to be diffed.
@param {string} text2 New string to be diffed.
@param {number} x Index of split point in text1.
@param {number} y Index of split point in text2.
@param {number} deadline Time at which to bail if not yet complete.
@return {!Array.<!diff_match_patch.Diff>} Array of diff tuples.
@private
###
diff_match_patch::diff_bisectSplit_ = (text1, text2, x, y, deadline) ->
  text1a = text1.substring(0, x)
  text2a = text2.substring(0, y)
  text1b = text1.substring(x)
  text2b = text2.substring(y)
  
  # Compute both diffs serially.
  diffs = @diff_main(text1a, text2a, false, deadline)
  diffsb = @diff_main(text1b, text2b, false, deadline)
  diffs.concat diffsb


###
Split two texts into an array of strings.  Reduce the texts to a string of
hashes where each Unicode character represents one line.
@param {string} text1 First string.
@param {string} text2 Second string.
@return {{chars1: string, chars2: string, lineArray: !Array.<string>}}
An object containing the encoded text1, the encoded text2 and
the array of unique strings.
The zeroth element of the array of unique strings is intentionally blank.
@private
###
diff_match_patch::diff_linesToChars_ = (text1, text2) ->
  # e.g. lineArray[4] == 'Hello\n'
  # e.g. lineHash['Hello\n'] == 4
  
  # '\x00' is a valid character, but various debuggers don't like it.
  # So we'll insert a junk entry to avoid generating a null character.
  
  ###
  Split a text into an array of strings.  Reduce the texts to a string of
  hashes where each Unicode character represents one line.
  Modifies linearray and linehash through being a closure.
  @param {string} text String to encode.
  @return {string} Encoded string.
  @private
  ###
  diff_linesToCharsMunge_ = (text) ->
    chars = ""
    
    # Walk the text, pulling out a substring for each line.
    # text.split('\n') would would temporarily double our memory footprint.
    # Modifying text would create many large strings to garbage collect.
    lineStart = 0
    lineEnd = -1
    
    # Keeping our own length variable is faster than looking it up.
    lineArrayLength = lineArray.length
    while lineEnd < text.length - 1
      lineEnd = text.indexOf("\n", lineStart)
      lineEnd = text.length - 1  if lineEnd is -1
      line = text.substring(lineStart, lineEnd + 1)
      lineStart = lineEnd + 1
      if (if lineHash.hasOwnProperty then lineHash.hasOwnProperty(line) else (lineHash[line] isnt `undefined`))
        chars += String.fromCharCode(lineHash[line])
      else
        chars += String.fromCharCode(lineArrayLength)
        lineHash[line] = lineArrayLength
        lineArray[lineArrayLength++] = line
    chars
  lineArray = []
  lineHash = {}
  lineArray[0] = ""
  chars1 = diff_linesToCharsMunge_(text1)
  chars2 = diff_linesToCharsMunge_(text2)
  chars1: chars1
  chars2: chars2
  lineArray: lineArray


###
Rehydrate the text in a diff from a string of line hashes to real lines of
text.
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
@param {!Array.<string>} lineArray Array of unique strings.
@private
###
diff_match_patch::diff_charsToLines_ = (diffs, lineArray) ->
  x = 0

  while x < diffs.length
    chars = diffs[x][1]
    text = []
    y = 0

    while y < chars.length
      text[y] = lineArray[chars.charCodeAt(y)]
      y++
    diffs[x][1] = text.join("")
    x++


###
Determine the common prefix of two strings.
@param {string} text1 First string.
@param {string} text2 Second string.
@return {number} The number of characters common to the start of each
string.
###
diff_match_patch::diff_commonPrefix = (text1, text2) ->
  
  # Quick check for common null cases.
  return 0  if not text1 or not text2 or text1.charAt(0) isnt text2.charAt(0)
  
  # Binary search.
  # Performance analysis: http://neil.fraser.name/news/2007/10/09/
  pointermin = 0
  pointermax = Math.min(text1.length, text2.length)
  pointermid = pointermax
  pointerstart = 0
  while pointermin < pointermid
    if text1.substring(pointerstart, pointermid) is text2.substring(pointerstart, pointermid)
      pointermin = pointermid
      pointerstart = pointermin
    else
      pointermax = pointermid
    pointermid = Math.floor((pointermax - pointermin) / 2 + pointermin)
  pointermid


###
Determine the common suffix of two strings.
@param {string} text1 First string.
@param {string} text2 Second string.
@return {number} The number of characters common to the end of each string.
###
diff_match_patch::diff_commonSuffix = (text1, text2) ->
  
  # Quick check for common null cases.
  return 0  if not text1 or not text2 or text1.charAt(text1.length - 1) isnt text2.charAt(text2.length - 1)
  
  # Binary search.
  # Performance analysis: http://neil.fraser.name/news/2007/10/09/
  pointermin = 0
  pointermax = Math.min(text1.length, text2.length)
  pointermid = pointermax
  pointerend = 0
  while pointermin < pointermid
    if text1.substring(text1.length - pointermid, text1.length - pointerend) is text2.substring(text2.length - pointermid, text2.length - pointerend)
      pointermin = pointermid
      pointerend = pointermin
    else
      pointermax = pointermid
    pointermid = Math.floor((pointermax - pointermin) / 2 + pointermin)
  pointermid


###
Determine if the suffix of one string is the prefix of another.
@param {string} text1 First string.
@param {string} text2 Second string.
@return {number} The number of characters common to the end of the first
string and the start of the second string.
@private
###
diff_match_patch::diff_commonOverlap_ = (text1, text2) ->
  
  # Cache the text lengths to prevent multiple calls.
  text1_length = text1.length
  text2_length = text2.length
  
  # Eliminate the null case.
  return 0  if text1_length is 0 or text2_length is 0
  
  # Truncate the longer string.
  if text1_length > text2_length
    text1 = text1.substring(text1_length - text2_length)
  else text2 = text2.substring(0, text1_length)  if text1_length < text2_length
  text_length = Math.min(text1_length, text2_length)
  
  # Quick check for the worst case.
  return text_length  if text1 is text2
  
  # Start by looking for a single character match
  # and increase length until no match is found.
  # Performance analysis: http://neil.fraser.name/news/2010/11/04/
  best = 0
  length = 1
  loop
    pattern = text1.substring(text_length - length)
    found = text2.indexOf(pattern)
    return best  if found is -1
    length += found
    if found is 0 or text1.substring(text_length - length) is text2.substring(0, length)
      best = length
      length++


###
Do the two texts share a substring which is at least half the length of the
longer text?
This speedup can produce non-minimal diffs.
@param {string} text1 First string.
@param {string} text2 Second string.
@return {Array.<string>} Five element Array, containing the prefix of
text1, the suffix of text1, the prefix of text2, the suffix of
text2 and the common middle.  Or null if there was no match.
@private
###
diff_match_patch::diff_halfMatch_ = (text1, text2) ->
  
  # Don't risk returning a non-optimal diff if we have unlimited time.
  # Pointless.
  # 'this' becomes 'window' in a closure.
  
  ###
  Does a substring of shorttext exist within longtext such that the substring
  is at least half the length of longtext?
  Closure, but does not reference any external variables.
  @param {string} longtext Longer string.
  @param {string} shorttext Shorter string.
  @param {number} i Start index of quarter length substring within longtext.
  @return {Array.<string>} Five element Array, containing the prefix of
  longtext, the suffix of longtext, the prefix of shorttext, the suffix
  of shorttext and the common middle.  Or null if there was no match.
  @private
  ###
  diff_halfMatchI_ = (longtext, shorttext, i) ->
    
    # Start with a 1/4 length substring at position i as a seed.
    seed = longtext.substring(i, i + Math.floor(longtext.length / 4))
    j = -1
    best_common = ""
    best_longtext_a = undefined
    best_longtext_b = undefined
    best_shorttext_a = undefined
    best_shorttext_b = undefined
    until (j = shorttext.indexOf(seed, j + 1)) is -1
      prefixLength = dmp.diff_commonPrefix(longtext.substring(i), shorttext.substring(j))
      suffixLength = dmp.diff_commonSuffix(longtext.substring(0, i), shorttext.substring(0, j))
      if best_common.length < suffixLength + prefixLength
        best_common = shorttext.substring(j - suffixLength, j) + shorttext.substring(j, j + prefixLength)
        best_longtext_a = longtext.substring(0, i - suffixLength)
        best_longtext_b = longtext.substring(i + prefixLength)
        best_shorttext_a = shorttext.substring(0, j - suffixLength)
        best_shorttext_b = shorttext.substring(j + prefixLength)
    if best_common.length * 2 >= longtext.length
      [best_longtext_a, best_longtext_b, best_shorttext_a, best_shorttext_b, best_common]
    else
      null
  return null  if @Diff_Timeout <= 0
  longtext = (if text1.length > text2.length then text1 else text2)
  shorttext = (if text1.length > text2.length then text2 else text1)
  return null  if longtext.length < 4 or shorttext.length * 2 < longtext.length
  dmp = this
  
  # First check if the second quarter is the seed for a half-match.
  hm1 = diff_halfMatchI_(longtext, shorttext, Math.ceil(longtext.length / 4))
  
  # Check again based on the third quarter.
  hm2 = diff_halfMatchI_(longtext, shorttext, Math.ceil(longtext.length / 2))
  hm = undefined
  if not hm1 and not hm2
    return null
  else unless hm2
    hm = hm1
  else unless hm1
    hm = hm2
  else
    
    # Both matched.  Select the longest.
    hm = (if hm1[4].length > hm2[4].length then hm1 else hm2)
  
  # A half-match was found, sort out the return data.
  text1_a = undefined
  text1_b = undefined
  text2_a = undefined
  text2_b = undefined
  if text1.length > text2.length
    text1_a = hm[0]
    text1_b = hm[1]
    text2_a = hm[2]
    text2_b = hm[3]
  else
    text2_a = hm[0]
    text2_b = hm[1]
    text1_a = hm[2]
    text1_b = hm[3]
  mid_common = hm[4]
  [text1_a, text1_b, text2_a, text2_b, mid_common]


###
Reduce the number of edits by eliminating semantically trivial equalities.
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
###
diff_match_patch::diff_cleanupSemantic = (diffs) ->
  changes = false
  equalities = [] # Stack of indices where equalities are found.
  equalitiesLength = 0 # Keeping our own length var is faster in JS.
  ###
  @type {?string}
  ###
  lastequality = null
  
  # Always equal to diffs[equalities[equalitiesLength - 1]][1]
  pointer = 0 # Index of current position.
  # Number of characters that changed prior to the equality.
  length_insertions1 = 0
  length_deletions1 = 0
  
  # Number of characters that changed after the equality.
  length_insertions2 = 0
  length_deletions2 = 0
  while pointer < diffs.length
    if diffs[pointer][0] is DIFF_EQUAL # Equality found.
      equalities[equalitiesLength++] = pointer
      length_insertions1 = length_insertions2
      length_deletions1 = length_deletions2
      length_insertions2 = 0
      length_deletions2 = 0
      lastequality = diffs[pointer][1]
    else # An insertion or deletion.
      if diffs[pointer][0] is DIFF_INSERT
        length_insertions2 += diffs[pointer][1].length
      else
        length_deletions2 += diffs[pointer][1].length
      
      # Eliminate an equality that is smaller or equal to the edits on both
      # sides of it.
      if lastequality and (lastequality.length <= Math.max(length_insertions1, length_deletions1)) and (lastequality.length <= Math.max(length_insertions2, length_deletions2))
        
        # Duplicate record.
        diffs.splice equalities[equalitiesLength - 1], 0, [DIFF_DELETE, lastequality]
        
        # Change second copy to insert.
        diffs[equalities[equalitiesLength - 1] + 1][0] = DIFF_INSERT
        
        # Throw away the equality we just deleted.
        equalitiesLength--
        
        # Throw away the previous equality (it needs to be reevaluated).
        equalitiesLength--
        pointer = (if equalitiesLength > 0 then equalities[equalitiesLength - 1] else -1)
        length_insertions1 = 0 # Reset the counters.
        length_deletions1 = 0
        length_insertions2 = 0
        length_deletions2 = 0
        lastequality = null
        changes = true
    pointer++
  
  # Normalize the diff.
  @diff_cleanupMerge diffs  if changes
  @diff_cleanupSemanticLossless diffs
  
  # Find any overlaps between deletions and insertions.
  # e.g: <del>abcxxx</del><ins>xxxdef</ins>
  #   -> <del>abc</del>xxx<ins>def</ins>
  # e.g: <del>xxxabc</del><ins>defxxx</ins>
  #   -> <ins>def</ins>xxx<del>abc</del>
  # Only extract an overlap if it is as big as the edit ahead or behind it.
  pointer = 1
  while pointer < diffs.length
    if diffs[pointer - 1][0] is DIFF_DELETE and diffs[pointer][0] is DIFF_INSERT
      deletion = diffs[pointer - 1][1]
      insertion = diffs[pointer][1]
      overlap_length1 = @diff_commonOverlap_(deletion, insertion)
      overlap_length2 = @diff_commonOverlap_(insertion, deletion)
      if overlap_length1 >= overlap_length2
        if overlap_length1 >= deletion.length / 2 or overlap_length1 >= insertion.length / 2
          
          # Overlap found.  Insert an equality and trim the surrounding edits.
          diffs.splice pointer, 0, [DIFF_EQUAL, insertion.substring(0, overlap_length1)]
          diffs[pointer - 1][1] = deletion.substring(0, deletion.length - overlap_length1)
          diffs[pointer + 1][1] = insertion.substring(overlap_length1)
          pointer++
      else
        if overlap_length2 >= deletion.length / 2 or overlap_length2 >= insertion.length / 2
          
          # Reverse overlap found.
          # Insert an equality and swap and trim the surrounding edits.
          diffs.splice pointer, 0, [DIFF_EQUAL, deletion.substring(0, overlap_length2)]
          diffs[pointer - 1][0] = DIFF_INSERT
          diffs[pointer - 1][1] = insertion.substring(0, insertion.length - overlap_length2)
          diffs[pointer + 1][0] = DIFF_DELETE
          diffs[pointer + 1][1] = deletion.substring(overlap_length2)
          pointer++
      pointer++
    pointer++


###
Look for single edits surrounded on both sides by equalities
which can be shifted sideways to align the edit to a word boundary.
e.g: The c<ins>at c</ins>ame. -> The <ins>cat </ins>came.
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
###
diff_match_patch::diff_cleanupSemanticLossless = (diffs) ->
  
  ###
  Given two strings, compute a score representing whether the internal
  boundary falls on logical boundaries.
  Scores range from 6 (best) to 0 (worst).
  Closure, but does not reference any external variables.
  @param {string} one First string.
  @param {string} two Second string.
  @return {number} The score.
  @private
  ###
  diff_cleanupSemanticScore_ = (one, two) ->
    
    # Edges are the best.
    return 6  if not one or not two
    
    # Each port of this function behaves slightly differently due to
    # subtle differences in each language's definition of things like
    # 'whitespace'.  Since this function's purpose is largely cosmetic,
    # the choice has been made to use each language's native features
    # rather than force total conformity.
    char1 = one.charAt(one.length - 1)
    char2 = two.charAt(0)
    nonAlphaNumeric1 = char1.match(diff_match_patch.nonAlphaNumericRegex_)
    nonAlphaNumeric2 = char2.match(diff_match_patch.nonAlphaNumericRegex_)
    whitespace1 = nonAlphaNumeric1 and char1.match(diff_match_patch.whitespaceRegex_)
    whitespace2 = nonAlphaNumeric2 and char2.match(diff_match_patch.whitespaceRegex_)
    lineBreak1 = whitespace1 and char1.match(diff_match_patch.linebreakRegex_)
    lineBreak2 = whitespace2 and char2.match(diff_match_patch.linebreakRegex_)
    blankLine1 = lineBreak1 and one.match(diff_match_patch.blanklineEndRegex_)
    blankLine2 = lineBreak2 and two.match(diff_match_patch.blanklineStartRegex_)
    if blankLine1 or blankLine2
      
      # Five points for blank lines.
      return 5
    else if lineBreak1 or lineBreak2
      
      # Four points for line breaks.
      return 4
    else if nonAlphaNumeric1 and not whitespace1 and whitespace2
      
      # Three points for end of sentences.
      return 3
    else if whitespace1 or whitespace2
      
      # Two points for whitespace.
      return 2
    
    # One point for non-alphanumeric.
    else return 1  if nonAlphaNumeric1 or nonAlphaNumeric2
    0
  pointer = 1
  
  # Intentionally ignore the first and last element (don't need checking).
  while pointer < diffs.length - 1
    if diffs[pointer - 1][0] is DIFF_EQUAL and diffs[pointer + 1][0] is DIFF_EQUAL
      
      # This is a single edit surrounded by equalities.
      equality1 = diffs[pointer - 1][1]
      edit = diffs[pointer][1]
      equality2 = diffs[pointer + 1][1]
      
      # First, shift the edit as far left as possible.
      commonOffset = @diff_commonSuffix(equality1, edit)
      if commonOffset
        commonString = edit.substring(edit.length - commonOffset)
        equality1 = equality1.substring(0, equality1.length - commonOffset)
        edit = commonString + edit.substring(0, edit.length - commonOffset)
        equality2 = commonString + equality2
      
      # Second, step character by character right, looking for the best fit.
      bestEquality1 = equality1
      bestEdit = edit
      bestEquality2 = equality2
      bestScore = diff_cleanupSemanticScore_(equality1, edit) + diff_cleanupSemanticScore_(edit, equality2)
      while edit.charAt(0) is equality2.charAt(0)
        equality1 += edit.charAt(0)
        edit = edit.substring(1) + equality2.charAt(0)
        equality2 = equality2.substring(1)
        score = diff_cleanupSemanticScore_(equality1, edit) + diff_cleanupSemanticScore_(edit, equality2)
        
        # The >= encourages trailing rather than leading whitespace on edits.
        if score >= bestScore
          bestScore = score
          bestEquality1 = equality1
          bestEdit = edit
          bestEquality2 = equality2
      unless diffs[pointer - 1][1] is bestEquality1
        
        # We have an improvement, save it back to the diff.
        if bestEquality1
          diffs[pointer - 1][1] = bestEquality1
        else
          diffs.splice pointer - 1, 1
          pointer--
        diffs[pointer][1] = bestEdit
        if bestEquality2
          diffs[pointer + 1][1] = bestEquality2
        else
          diffs.splice pointer + 1, 1
          pointer--
    pointer++


# Define some regex patterns for matching boundaries.
diff_match_patch.nonAlphaNumericRegex_ = /[^a-zA-Z0-9]/
diff_match_patch.whitespaceRegex_ = /\s/
diff_match_patch.linebreakRegex_ = /[\r\n]/
diff_match_patch.blanklineEndRegex_ = /\n\r?\n$/
diff_match_patch.blanklineStartRegex_ = /^\r?\n\r?\n/

###
Reduce the number of edits by eliminating operationally trivial equalities.
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
###
diff_match_patch::diff_cleanupEfficiency = (diffs) ->
  changes = false
  equalities = [] # Stack of indices where equalities are found.
  equalitiesLength = 0 # Keeping our own length var is faster in JS.
  ###
  @type {?string}
  ###
  lastequality = null
  
  # Always equal to diffs[equalities[equalitiesLength - 1]][1]
  pointer = 0 # Index of current position.
  # Is there an insertion operation before the last equality.
  pre_ins = false
  
  # Is there a deletion operation before the last equality.
  pre_del = false
  
  # Is there an insertion operation after the last equality.
  post_ins = false
  
  # Is there a deletion operation after the last equality.
  post_del = false
  while pointer < diffs.length
    if diffs[pointer][0] is DIFF_EQUAL # Equality found.
      if diffs[pointer][1].length < @Diff_EditCost and (post_ins or post_del)
        
        # Candidate found.
        equalities[equalitiesLength++] = pointer
        pre_ins = post_ins
        pre_del = post_del
        lastequality = diffs[pointer][1]
      else
        
        # Not a candidate, and can never become one.
        equalitiesLength = 0
        lastequality = null
      post_ins = post_del = false
    else # An insertion or deletion.
      if diffs[pointer][0] is DIFF_DELETE
        post_del = true
      else
        post_ins = true
      
      #
      #       * Five types to be split:
      #       * <ins>A</ins><del>B</del>XY<ins>C</ins><del>D</del>
      #       * <ins>A</ins>X<ins>C</ins><del>D</del>
      #       * <ins>A</ins><del>B</del>X<ins>C</ins>
      #       * <ins>A</del>X<ins>C</ins><del>D</del>
      #       * <ins>A</ins><del>B</del>X<del>C</del>
      #       
      if lastequality and ((pre_ins and pre_del and post_ins and post_del) or ((lastequality.length < @Diff_EditCost / 2) and (pre_ins + pre_del + post_ins + post_del) is 3))
        
        # Duplicate record.
        diffs.splice equalities[equalitiesLength - 1], 0, [DIFF_DELETE, lastequality]
        
        # Change second copy to insert.
        diffs[equalities[equalitiesLength - 1] + 1][0] = DIFF_INSERT
        equalitiesLength-- # Throw away the equality we just deleted;
        lastequality = null
        if pre_ins and pre_del
          
          # No changes made which could affect previous entry, keep going.
          post_ins = post_del = true
          equalitiesLength = 0
        else
          equalitiesLength-- # Throw away the previous equality.
          pointer = (if equalitiesLength > 0 then equalities[equalitiesLength - 1] else -1)
          post_ins = post_del = false
        changes = true
    pointer++
  @diff_cleanupMerge diffs  if changes


###
Reorder and merge like edit sections.  Merge equalities.
Any edit section can move as long as it doesn't cross an equality.
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
###
diff_match_patch::diff_cleanupMerge = (diffs) ->
  diffs.push [DIFF_EQUAL, ""] # Add a dummy entry at the end.
  pointer = 0
  count_delete = 0
  count_insert = 0
  text_delete = ""
  text_insert = ""
  commonlength = undefined
  while pointer < diffs.length
    switch diffs[pointer][0]
      when DIFF_INSERT
        count_insert++
        text_insert += diffs[pointer][1]
        pointer++
      when DIFF_DELETE
        count_delete++
        text_delete += diffs[pointer][1]
        pointer++
      when DIFF_EQUAL
        
        # Upon reaching an equality, check for prior redundancies.
        if count_delete + count_insert > 1
          if count_delete isnt 0 and count_insert isnt 0
            
            # Factor out any common prefixies.
            commonlength = @diff_commonPrefix(text_insert, text_delete)
            if commonlength isnt 0
              if (pointer - count_delete - count_insert) > 0 and diffs[pointer - count_delete - count_insert - 1][0] is DIFF_EQUAL
                diffs[pointer - count_delete - count_insert - 1][1] += text_insert.substring(0, commonlength)
              else
                diffs.splice 0, 0, [DIFF_EQUAL, text_insert.substring(0, commonlength)]
                pointer++
              text_insert = text_insert.substring(commonlength)
              text_delete = text_delete.substring(commonlength)
            
            # Factor out any common suffixies.
            commonlength = @diff_commonSuffix(text_insert, text_delete)
            if commonlength isnt 0
              diffs[pointer][1] = text_insert.substring(text_insert.length - commonlength) + diffs[pointer][1]
              text_insert = text_insert.substring(0, text_insert.length - commonlength)
              text_delete = text_delete.substring(0, text_delete.length - commonlength)
          
          # Delete the offending records and add the merged ones.
          if count_delete is 0
            diffs.splice pointer - count_insert, count_delete + count_insert, [DIFF_INSERT, text_insert]
          else if count_insert is 0
            diffs.splice pointer - count_delete, count_delete + count_insert, [DIFF_DELETE, text_delete]
          else
            diffs.splice pointer - count_delete - count_insert, count_delete + count_insert, [DIFF_DELETE, text_delete], [DIFF_INSERT, text_insert]
          pointer = pointer - count_delete - count_insert + ((if count_delete then 1 else 0)) + ((if count_insert then 1 else 0)) + 1
        else if pointer isnt 0 and diffs[pointer - 1][0] is DIFF_EQUAL
          
          # Merge this equality with the previous one.
          diffs[pointer - 1][1] += diffs[pointer][1]
          diffs.splice pointer, 1
        else
          pointer++
        count_insert = 0
        count_delete = 0
        text_delete = ""
        text_insert = ""
  diffs.pop()  if diffs[diffs.length - 1][1] is "" # Remove the dummy entry at the end.
  
  # Second pass: look for single edits surrounded on both sides by equalities
  # which can be shifted sideways to eliminate an equality.
  # e.g: A<ins>BA</ins>C -> <ins>AB</ins>AC
  changes = false
  pointer = 1
  
  # Intentionally ignore the first and last element (don't need checking).
  while pointer < diffs.length - 1
    if diffs[pointer - 1][0] is DIFF_EQUAL and diffs[pointer + 1][0] is DIFF_EQUAL
      
      # This is a single edit surrounded by equalities.
      if diffs[pointer][1].substring(diffs[pointer][1].length - diffs[pointer - 1][1].length) is diffs[pointer - 1][1]
        
        # Shift the edit over the previous equality.
        diffs[pointer][1] = diffs[pointer - 1][1] + diffs[pointer][1].substring(0, diffs[pointer][1].length - diffs[pointer - 1][1].length)
        diffs[pointer + 1][1] = diffs[pointer - 1][1] + diffs[pointer + 1][1]
        diffs.splice pointer - 1, 1
        changes = true
      else if diffs[pointer][1].substring(0, diffs[pointer + 1][1].length) is diffs[pointer + 1][1]
        
        # Shift the edit over the next equality.
        diffs[pointer - 1][1] += diffs[pointer + 1][1]
        diffs[pointer][1] = diffs[pointer][1].substring(diffs[pointer + 1][1].length) + diffs[pointer + 1][1]
        diffs.splice pointer + 1, 1
        changes = true
    pointer++
  
  # If shifts were made, the diff needs reordering and another shift sweep.
  @diff_cleanupMerge diffs  if changes


###
loc is a location in text1, compute and return the equivalent location in
text2.
e.g. 'The cat' vs 'The big cat', 1->1, 5->8
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
@param {number} loc Location within text1.
@return {number} Location within text2.
###
diff_match_patch::diff_xIndex = (diffs, loc) ->
  chars1 = 0
  chars2 = 0
  last_chars1 = 0
  last_chars2 = 0
  x = undefined
  x = 0
  while x < diffs.length
    # Equality or deletion.
    chars1 += diffs[x][1].length  if diffs[x][0] isnt DIFF_INSERT
    # Equality or insertion.
    chars2 += diffs[x][1].length  if diffs[x][0] isnt DIFF_DELETE
    # Overshot the location.
    break  if chars1 > loc
    last_chars1 = chars1
    last_chars2 = chars2
    x++
  
  # Was the location was deleted?
  return last_chars2  if diffs.length isnt x and diffs[x][0] is DIFF_DELETE
  
  # Add the remaining character length.
  last_chars2 + (loc - last_chars1)


###
Convert a diff array into a pretty HTML report.
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
@return {string} HTML representation.
###
diff_match_patch::diff_prettyHtml = (diffs) ->
  html = []
  pattern_amp = /&/g
  pattern_lt = /</g
  pattern_gt = />/g
  pattern_para = /\n/g
  x = 0

  while x < diffs.length
    op = diffs[x][0] # Operation (insert, delete, equal)
    data = diffs[x][1] # Text of change.
    text = data.replace(pattern_amp, "&amp;").replace(pattern_lt, "&lt;").replace(pattern_gt, "&gt;").replace(pattern_para, "&para;<br>")
    switch op
      when DIFF_INSERT
        html[x] = "<ins style=\"background:#e6ffe6;\">" + text + "</ins>"
      when DIFF_DELETE
        html[x] = "<del style=\"background:#ffe6e6;\">" + text + "</del>"
      when DIFF_EQUAL
        html[x] = "<span>" + text + "</span>"
    x++
  html.join ""


###
Compute and return the source text (all equalities and deletions).
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
@return {string} Source text.
###
diff_match_patch::diff_text1 = (diffs) ->
  text = []
  x = 0

  while x < diffs.length
    text[x] = diffs[x][1]  if diffs[x][0] isnt DIFF_INSERT
    x++
  text.join ""


###
Compute and return the destination text (all equalities and insertions).
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
@return {string} Destination text.
###
diff_match_patch::diff_text2 = (diffs) ->
  text = []
  x = 0

  while x < diffs.length
    text[x] = diffs[x][1]  if diffs[x][0] isnt DIFF_DELETE
    x++
  text.join ""


###
Compute the Levenshtein distance; the number of inserted, deleted or
substituted characters.
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
@return {number} Number of changes.
###
diff_match_patch::diff_levenshtein = (diffs) ->
  levenshtein = 0
  insertions = 0
  deletions = 0
  x = 0

  while x < diffs.length
    op = diffs[x][0]
    data = diffs[x][1]
    switch op
      when DIFF_INSERT
        insertions += data.length
      when DIFF_DELETE
        deletions += data.length
      when DIFF_EQUAL
        
        # A deletion and an insertion is one substitution.
        levenshtein += Math.max(insertions, deletions)
        insertions = 0
        deletions = 0
    x++
  levenshtein += Math.max(insertions, deletions)
  levenshtein


###
Crush the diff into an encoded string which describes the operations
required to transform text1 into text2.
E.g. =3\t-2\t+ing  -> Keep 3 chars, delete 2 chars, insert 'ing'.
Operations are tab-separated.  Inserted text is escaped using %xx notation.
@param {!Array.<!diff_match_patch.Diff>} diffs Array of diff tuples.
@return {string} Delta text.
###
diff_match_patch::diff_toDelta = (diffs) ->
  text = []
  x = 0

  while x < diffs.length
    switch diffs[x][0]
      when DIFF_INSERT
        text[x] = "+" + encodeURI(diffs[x][1])
      when DIFF_DELETE
        text[x] = "-" + diffs[x][1].length
      when DIFF_EQUAL
        text[x] = "=" + diffs[x][1].length
    x++
  text.join("\t").replace /%20/g, " "


###
Given the original text1, and an encoded string which describes the
operations required to transform text1 into text2, compute the full diff.
@param {string} text1 Source string for the diff.
@param {string} delta Delta text.
@return {!Array.<!diff_match_patch.Diff>} Array of diff tuples.
@throws {!Error} If invalid input.
###
diff_match_patch::diff_fromDelta = (text1, delta) ->
  diffs = []
  diffsLength = 0 # Keeping our own length var is faster in JS.
  pointer = 0 # Cursor in text1
  tokens = delta.split(/\t/g)
  x = 0

  while x < tokens.length
    
    # Each token begins with a one character parameter which specifies the
    # operation of this token (delete, insert, equality).
    param = tokens[x].substring(1)
    switch tokens[x].charAt(0)
      when "+"
        try
          diffs[diffsLength++] = [DIFF_INSERT, decodeURI(param)]
        catch ex
          
          # Malformed URI sequence.
          throw new Error("Illegal escape in diff_fromDelta: " + param)
      
      # Fall through.
      when "-", "="
        n = parseInt(param, 10)
        throw new Error("Invalid number in diff_fromDelta: " + param)  if isNaN(n) or n < 0
        text = text1.substring(pointer, pointer += n)
        if tokens[x].charAt(0) is "="
          diffs[diffsLength++] = [DIFF_EQUAL, text]
        else
          diffs[diffsLength++] = [DIFF_DELETE, text]
      else
        
        # Blank tokens are ok (from a trailing \t).
        # Anything else is an error.
        throw new Error("Invalid diff operation in diff_fromDelta: " + tokens[x])  if tokens[x]
    x++
  throw new Error("Delta length (" + pointer + ") does not equal source text length (" + text1.length + ").")  unless pointer is text1.length
  diffs


#  MATCH FUNCTIONS

###
Locate the best instance of 'pattern' in 'text' near 'loc'.
@param {string} text The text to search.
@param {string} pattern The pattern to search for.
@param {number} loc The location to search around.
@return {number} Best match index or -1.
###
diff_match_patch::match_main = (text, pattern, loc) ->
  
  # Check for null inputs.
  throw new Error("Null input. (match_main)")  if not text? or not pattern? or not loc?
  loc = Math.max(0, Math.min(loc, text.length))
  if text is pattern
    
    # Shortcut (potentially not guaranteed by the algorithm)
    0
  else unless text.length
    
    # Nothing to match.
    -1
  else if text.substring(loc, loc + pattern.length) is pattern
    
    # Perfect match at the perfect spot!  (Includes case of null pattern)
    loc
  else
    
    # Do a fuzzy compare.
    @match_bitap_ text, pattern, loc


###
Locate the best instance of 'pattern' in 'text' near 'loc' using the
Bitap algorithm.
@param {string} text The text to search.
@param {string} pattern The pattern to search for.
@param {number} loc The location to search around.
@return {number} Best match index or -1.
@private
###
diff_match_patch::match_bitap_ = (text, pattern, loc) ->
  
  # Initialise the alphabet.
  # 'this' becomes 'window' in a closure.
  
  ###
  Compute and return the score for a match with e errors and x location.
  Accesses loc and pattern through being a closure.
  @param {number} e Number of errors in match.
  @param {number} x Location of match.
  @return {number} Overall score for match (0.0 = good, 1.0 = bad).
  @private
  ###
  match_bitapScore_ = (e, x) ->
    accuracy = e / pattern.length
    proximity = Math.abs(loc - x)
    
    # Dodge divide by zero error.
    return (if proximity then 1.0 else accuracy)  unless dmp.Match_Distance
    accuracy + (proximity / dmp.Match_Distance)
  throw new Error("Pattern too long for this browser.")  if pattern.length > @Match_MaxBits
  s = @match_alphabet_(pattern)
  dmp = this
  
  # Highest score beyond which we give up.
  score_threshold = @Match_Threshold
  
  # Is there a nearby exact match? (speedup)
  best_loc = text.indexOf(pattern, loc)
  unless best_loc is -1
    score_threshold = Math.min(match_bitapScore_(0, best_loc), score_threshold)
    
    # What about in the other direction? (speedup)
    best_loc = text.lastIndexOf(pattern, loc + pattern.length)
    score_threshold = Math.min(match_bitapScore_(0, best_loc), score_threshold)  unless best_loc is -1
  
  # Initialise the bit arrays.
  matchmask = 1 << (pattern.length - 1)
  best_loc = -1
  bin_min = undefined
  bin_mid = undefined
  bin_max = pattern.length + text.length
  last_rd = undefined
  d = 0

  while d < pattern.length
    
    # Scan for the best match; each iteration allows for one more error.
    # Run a binary search to determine how far from 'loc' we can stray at this
    # error level.
    bin_min = 0
    bin_mid = bin_max
    while bin_min < bin_mid
      if match_bitapScore_(d, loc + bin_mid) <= score_threshold
        bin_min = bin_mid
      else
        bin_max = bin_mid
      bin_mid = Math.floor((bin_max - bin_min) / 2 + bin_min)
    
    # Use the result from this iteration as the maximum for the next.
    bin_max = bin_mid
    start = Math.max(1, loc - bin_mid + 1)
    finish = Math.min(loc + bin_mid, text.length) + pattern.length
    rd = Array(finish + 2)
    rd[finish + 1] = (1 << d) - 1
    j = finish

    while j >= start
      
      # The alphabet (s) is a sparse hash, so the following line generates
      # warnings.
      charMatch = s[text.charAt(j - 1)]
      if d is 0 # First pass: exact match.
        rd[j] = ((rd[j + 1] << 1) | 1) & charMatch
      else # Subsequent passes: fuzzy match.
        rd[j] = (((rd[j + 1] << 1) | 1) & charMatch) | (((last_rd[j + 1] | last_rd[j]) << 1) | 1) | last_rd[j + 1]
      if rd[j] & matchmask
        score = match_bitapScore_(d, j - 1)
        
        # This match will almost certainly be better than any existing match.
        # But check anyway.
        if score <= score_threshold
          
          # Told you so.
          score_threshold = score
          best_loc = j - 1
          if best_loc > loc
            
            # When passing loc, don't exceed our current distance from loc.
            start = Math.max(1, 2 * loc - best_loc)
          else
            
            # Already passed loc, downhill from here on in.
            break
      j--
    
    # No hope for a (better) match at greater error levels.
    break  if match_bitapScore_(d + 1, loc) > score_threshold
    last_rd = rd
    d++
  best_loc


###
Initialise the alphabet for the Bitap algorithm.
@param {string} pattern The text to encode.
@return {!Object} Hash of character locations.
@private
###
diff_match_patch::match_alphabet_ = (pattern) ->
  s = {}
  i = 0

  while i < pattern.length
    s[pattern.charAt(i)] = 0
    i++
  i = 0

  while i < pattern.length
    s[pattern.charAt(i)] |= 1 << (pattern.length - i - 1)
    i++
  s


#  PATCH FUNCTIONS

###
Increase the context until it is unique,
but don't let the pattern expand beyond Match_MaxBits.
@param {!diff_match_patch.patch_obj} patch The patch to grow.
@param {string} text Source text.
@private
###
diff_match_patch::patch_addContext_ = (patch, text) ->
  return  if text.length is 0
  pattern = text.substring(patch.start2, patch.start2 + patch.length1)
  padding = 0
  
  # Look for the first and last matches of pattern in text.  If two different
  # matches are found, increase the pattern length.
  while text.indexOf(pattern) isnt text.lastIndexOf(pattern) and pattern.length < @Match_MaxBits - @Patch_Margin - @Patch_Margin
    padding += @Patch_Margin
    pattern = text.substring(patch.start2 - padding, patch.start2 + patch.length1 + padding)
  
  # Add one chunk for good luck.
  padding += @Patch_Margin
  
  # Add the prefix.
  prefix = text.substring(patch.start2 - padding, patch.start2)
  patch.diffs.unshift [DIFF_EQUAL, prefix]  if prefix
  
  # Add the suffix.
  suffix = text.substring(patch.start2 + patch.length1, patch.start2 + patch.length1 + padding)
  patch.diffs.push [DIFF_EQUAL, suffix]  if suffix
  
  # Roll back the start points.
  patch.start1 -= prefix.length
  patch.start2 -= prefix.length
  
  # Extend the lengths.
  patch.length1 += prefix.length + suffix.length
  patch.length2 += prefix.length + suffix.length


###
Compute a list of patches to turn text1 into text2.
Use diffs if provided, otherwise compute it ourselves.
There are four ways to call this function, depending on what data is
available to the caller:
Method 1:
a = text1, b = text2
Method 2:
a = diffs
Method 3 (optimal):
a = text1, b = diffs
Method 4 (deprecated, use method 3):
a = text1, b = text2, c = diffs

@param {string|!Array.<!diff_match_patch.Diff>} a text1 (methods 1,3,4) or
Array of diff tuples for text1 to text2 (method 2).
@param {string|!Array.<!diff_match_patch.Diff>} opt_b text2 (methods 1,4) or
Array of diff tuples for text1 to text2 (method 3) or undefined (method 2).
@param {string|!Array.<!diff_match_patch.Diff>} opt_c Array of diff tuples
for text1 to text2 (method 4) or undefined (methods 1,2,3).
@return {!Array.<!diff_match_patch.patch_obj>} Array of Patch objects.
###
diff_match_patch::patch_make = (a, opt_b, opt_c) ->
  text1 = undefined
  diffs = undefined
  if typeof a is "string" and typeof opt_b is "string" and typeof opt_c is "undefined"
    
    # Method 1: text1, text2
    # Compute diffs from text1 and text2.
    text1 = (a) 
    ###
@type {string}
###
    diffs = @diff_main(text1, (opt_b), true)
    ###
@type {string}
###
  if diffs.length > 2
      @diff_cleanupSemantic diffs
      @diff_cleanupEfficiency diffs
  else if a and typeof a is "object" and typeof opt_b is "undefined" and typeof opt_c is "undefined"
    
    # Method 2: diffs
    # Compute text1 from diffs.
    diffs = (a) 
    ###
@type {!Array.<!diff_match_patch.Diff>}
###
    text1 = @diff_text1(diffs)
  else if typeof a is "string" and opt_b and typeof opt_b is "object" and typeof opt_c is "undefined"
    
    # Method 3: text1, diffs
    text1 = (a)
    ###
@type {string}
###
    diffs = (opt_b)
    ###
@type {!Array.<!diff_match_patch.Diff>}
###
  else if typeof a is "string" and typeof opt_b is "string" and opt_c and typeof opt_c is "object"
    
    # Method 4: text1, text2, diffs
    # text2 is not used.
    text1 = (a)
    ###
@type {string}
###
    diffs = (opt_c)
    ###
@type {!Array.<!diff_match_patch.Diff>}
###
  else
    throw new Error("Unknown call format to patch_make.")
  return []  if diffs.length is 0 # Get rid of the null case.
  patches = []
  patch = new diff_match_patch.patch_obj()
  patchDiffLength = 0 # Keeping our own length var is faster in JS.
  char_count1 = 0 # Number of characters into the text1 string.
  char_count2 = 0 # Number of characters into the text2 string.
  # Start with text1 (prepatch_text) and apply the diffs until we arrive at
  # text2 (postpatch_text).  We recreate the patches one by one to determine
  # context info.
  prepatch_text = text1
  postpatch_text = text1
  x = 0

  while x < diffs.length
    diff_type = diffs[x][0]
    diff_text = diffs[x][1]
    if not patchDiffLength and diff_type isnt DIFF_EQUAL
      
      # A new patch starts here.
      patch.start1 = char_count1
      patch.start2 = char_count2
    switch diff_type
      when DIFF_INSERT
        patch.diffs[patchDiffLength++] = diffs[x]
        patch.length2 += diff_text.length
        postpatch_text = postpatch_text.substring(0, char_count2) + diff_text + postpatch_text.substring(char_count2)
      when DIFF_DELETE
        patch.length1 += diff_text.length
        patch.diffs[patchDiffLength++] = diffs[x]
        postpatch_text = postpatch_text.substring(0, char_count2) + postpatch_text.substring(char_count2 + diff_text.length)
      when DIFF_EQUAL
        if diff_text.length <= 2 * @Patch_Margin and patchDiffLength and diffs.length isnt x + 1
          
          # Small equality inside a patch.
          patch.diffs[patchDiffLength++] = diffs[x]
          patch.length1 += diff_text.length
          patch.length2 += diff_text.length
        else if diff_text.length >= 2 * @Patch_Margin
          
          # Time for a new patch.
          if patchDiffLength
            @patch_addContext_ patch, prepatch_text
            patches.push patch
            patch = new diff_match_patch.patch_obj()
            patchDiffLength = 0
            
            # Unlike Unidiff, our patch lists have a rolling context.
            # http://code.google.com/p/google-diff-match-patch/wiki/Unidiff
            # Update prepatch text & pos to reflect the application of the
            # just completed patch.
            prepatch_text = postpatch_text
            char_count1 = char_count2
    
    # Update the current character count.
    char_count1 += diff_text.length  if diff_type isnt DIFF_INSERT
    char_count2 += diff_text.length  if diff_type isnt DIFF_DELETE
    x++
  
  # Pick up the leftover patch if not empty.
  if patchDiffLength
    @patch_addContext_ patch, prepatch_text
    patches.push patch
  patches


###
Given an array of patches, return another array that is identical.
@param {!Array.<!diff_match_patch.patch_obj>} patches Array of Patch objects.
@return {!Array.<!diff_match_patch.patch_obj>} Array of Patch objects.
###
diff_match_patch::patch_deepCopy = (patches) ->
  
  # Making deep copies is hard in JavaScript.
  patchesCopy = []
  x = 0

  while x < patches.length
    patch = patches[x]
    patchCopy = new diff_match_patch.patch_obj()
    patchCopy.diffs = []
    y = 0

    while y < patch.diffs.length
      patchCopy.diffs[y] = patch.diffs[y].slice()
      y++
    patchCopy.start1 = patch.start1
    patchCopy.start2 = patch.start2
    patchCopy.length1 = patch.length1
    patchCopy.length2 = patch.length2
    patchesCopy[x] = patchCopy
    x++
  patchesCopy


###
Merge a set of patches onto the text.  Return a patched text, as well
as a list of true/false values indicating which patches were applied.
@param {!Array.<!diff_match_patch.patch_obj>} patches Array of Patch objects.
@param {string} text Old text.
@return {!Array.<string|!Array.<boolean>>} Two element Array, containing the
new text and an array of boolean values.
###
diff_match_patch::patch_apply = (patches, text) ->
  return [text, []]  if patches.length is 0
  
  # Deep copy the patches so that no changes are made to originals.
  patches = @patch_deepCopy(patches)
  nullPadding = @patch_addPadding(patches)
  text = nullPadding + text + nullPadding
  @patch_splitMax patches
  
  # delta keeps track of the offset between the expected and actual location
  # of the previous patch.  If there are patches expected at positions 10 and
  # 20, but the first patch was found at 12, delta is 2 and the second patch
  # has an effective expected position of 22.
  delta = 0
  results = []
  x = 0

  while x < patches.length
    expected_loc = patches[x].start2 + delta
    text1 = @diff_text1(patches[x].diffs)
    start_loc = undefined
    end_loc = -1
    if text1.length > @Match_MaxBits
      
      # patch_splitMax will only provide an oversized pattern in the case of
      # a monster delete.
      start_loc = @match_main(text, text1.substring(0, @Match_MaxBits), expected_loc)
      unless start_loc is -1
        end_loc = @match_main(text, text1.substring(text1.length - @Match_MaxBits), expected_loc + text1.length - @Match_MaxBits)
        
        # Can't find valid trailing context.  Drop this patch.
        start_loc = -1  if end_loc is -1 or start_loc >= end_loc
    else
      start_loc = @match_main(text, text1, expected_loc)
    if start_loc is -1
      
      # No match found.  :(
      results[x] = false
      
      # Subtract the delta for this failed patch from subsequent patches.
      delta -= patches[x].length2 - patches[x].length1
    else
      
      # Found a match.  :)
      results[x] = true
      delta = start_loc - expected_loc
      text2 = undefined
      if end_loc is -1
        text2 = text.substring(start_loc, start_loc + text1.length)
      else
        text2 = text.substring(start_loc, end_loc + @Match_MaxBits)
      if text1 is text2
        
        # Perfect match, just shove the replacement text in.
        text = text.substring(0, start_loc) + @diff_text2(patches[x].diffs) + text.substring(start_loc + text1.length)
      else
        
        # Imperfect match.  Run a diff to get a framework of equivalent
        # indices.
        diffs = @diff_main(text1, text2, false)
        if text1.length > @Match_MaxBits and @diff_levenshtein(diffs) / text1.length > @Patch_DeleteThreshold
          
          # The end points match, but the content is unacceptably bad.
          results[x] = false
        else
          @diff_cleanupSemanticLossless diffs
          index1 = 0
          index2 = undefined
          y = 0

          while y < patches[x].diffs.length
            mod = patches[x].diffs[y]
            index2 = @diff_xIndex(diffs, index1)  if mod[0] isnt DIFF_EQUAL
            if mod[0] is DIFF_INSERT # Insertion
              text = text.substring(0, start_loc + index2) + mod[1] + text.substring(start_loc + index2)
            # Deletion
            else text = text.substring(0, start_loc + index2) + text.substring(start_loc + @diff_xIndex(diffs, index1 + mod[1].length))  if mod[0] is DIFF_DELETE
            index1 += mod[1].length  if mod[0] isnt DIFF_DELETE
            y++
    x++
  
  # Strip the padding off.
  text = text.substring(nullPadding.length, text.length - nullPadding.length)
  [text, results]


###
Add some padding on text start and end so that edges can match something.
Intended to be called only from within patch_apply.
@param {!Array.<!diff_match_patch.patch_obj>} patches Array of Patch objects.
@return {string} The padding string added to each side.
###
diff_match_patch::patch_addPadding = (patches) ->
  paddingLength = @Patch_Margin
  nullPadding = ""
  x = 1

  while x <= paddingLength
    nullPadding += String.fromCharCode(x)
    x++
  
  # Bump all the patches forward.
  x = 0

  while x < patches.length
    patches[x].start1 += paddingLength
    patches[x].start2 += paddingLength
    x++
  
  # Add some padding on start of first diff.
  patch = patches[0]
  diffs = patch.diffs
  if diffs.length is 0 or diffs[0][0] isnt DIFF_EQUAL
    
    # Add nullPadding equality.
    diffs.unshift [DIFF_EQUAL, nullPadding]
    patch.start1 -= paddingLength # Should be 0.
    patch.start2 -= paddingLength # Should be 0.
    patch.length1 += paddingLength
    patch.length2 += paddingLength
  else if paddingLength > diffs[0][1].length
    
    # Grow first equality.
    extraLength = paddingLength - diffs[0][1].length
    diffs[0][1] = nullPadding.substring(diffs[0][1].length) + diffs[0][1]
    patch.start1 -= extraLength
    patch.start2 -= extraLength
    patch.length1 += extraLength
    patch.length2 += extraLength
  
  # Add some padding on end of last diff.
  patch = patches[patches.length - 1]
  diffs = patch.diffs
  if diffs.length is 0 or diffs[diffs.length - 1][0] isnt DIFF_EQUAL
    
    # Add nullPadding equality.
    diffs.push [DIFF_EQUAL, nullPadding]
    patch.length1 += paddingLength
    patch.length2 += paddingLength
  else if paddingLength > diffs[diffs.length - 1][1].length
    
    # Grow last equality.
    extraLength = paddingLength - diffs[diffs.length - 1][1].length
    diffs[diffs.length - 1][1] += nullPadding.substring(0, extraLength)
    patch.length1 += extraLength
    patch.length2 += extraLength
  nullPadding


###
Look through the patches and break up any which are longer than the maximum
limit of the match algorithm.
Intended to be called only from within patch_apply.
@param {!Array.<!diff_match_patch.patch_obj>} patches Array of Patch objects.
###
diff_match_patch::patch_splitMax = (patches) ->
  patch_size = @Match_MaxBits
  x = 0

  while x < patches.length
    continue  if patches[x].length1 <= patch_size
    bigpatch = patches[x]
    
    # Remove the big old patch.
    patches.splice x--, 1
    start1 = bigpatch.start1
    start2 = bigpatch.start2
    precontext = ""
    while bigpatch.diffs.length isnt 0
      
      # Create one of several smaller patches.
      patch = new diff_match_patch.patch_obj()
      empty = true
      patch.start1 = start1 - precontext.length
      patch.start2 = start2 - precontext.length
      if precontext isnt ""
        patch.length1 = patch.length2 = precontext.length
        patch.diffs.push [DIFF_EQUAL, precontext]
      while bigpatch.diffs.length isnt 0 and patch.length1 < patch_size - @Patch_Margin
        diff_type = bigpatch.diffs[0][0]
        diff_text = bigpatch.diffs[0][1]
        if diff_type is DIFF_INSERT
          
          # Insertions are harmless.
          patch.length2 += diff_text.length
          start2 += diff_text.length
          patch.diffs.push bigpatch.diffs.shift()
          empty = false
        else if diff_type is DIFF_DELETE and patch.diffs.length is 1 and patch.diffs[0][0] is DIFF_EQUAL and diff_text.length > 2 * patch_size
          
          # This is a large deletion.  Let it pass in one chunk.
          patch.length1 += diff_text.length
          start1 += diff_text.length
          empty = false
          patch.diffs.push [diff_type, diff_text]
          bigpatch.diffs.shift()
        else
          
          # Deletion or equality.  Only take as much as we can stomach.
          diff_text = diff_text.substring(0, patch_size - patch.length1 - @Patch_Margin)
          patch.length1 += diff_text.length
          start1 += diff_text.length
          if diff_type is DIFF_EQUAL
            patch.length2 += diff_text.length
            start2 += diff_text.length
          else
            empty = false
          patch.diffs.push [diff_type, diff_text]
          if diff_text is bigpatch.diffs[0][1]
            bigpatch.diffs.shift()
          else
            bigpatch.diffs[0][1] = bigpatch.diffs[0][1].substring(diff_text.length)
      
      # Compute the head context for the next patch.
      precontext = @diff_text2(patch.diffs)
      precontext = precontext.substring(precontext.length - @Patch_Margin)
      
      # Append the end context for this patch.
      postcontext = @diff_text1(bigpatch.diffs).substring(0, @Patch_Margin)
      if postcontext isnt ""
        patch.length1 += postcontext.length
        patch.length2 += postcontext.length
        if patch.diffs.length isnt 0 and patch.diffs[patch.diffs.length - 1][0] is DIFF_EQUAL
          patch.diffs[patch.diffs.length - 1][1] += postcontext
        else
          patch.diffs.push [DIFF_EQUAL, postcontext]
      patches.splice ++x, 0, patch  unless empty
    x++


###
Take a list of patches and return a textual representation.
@param {!Array.<!diff_match_patch.patch_obj>} patches Array of Patch objects.
@return {string} Text representation of patches.
###
diff_match_patch::patch_toText = (patches) ->
  text = []
  x = 0

  while x < patches.length
    text[x] = patches[x]
    x++
  text.join ""


###
Parse a textual representation of patches and return a list of Patch objects.
@param {string} textline Text representation of patches.
@return {!Array.<!diff_match_patch.patch_obj>} Array of Patch objects.
@throws {!Error} If invalid input.
###
diff_match_patch::patch_fromText = (textline) ->
  patches = []
  return patches  unless textline
  text = textline.split("\n")
  textPointer = 0
  patchHeader = /^@@ -(\d+),?(\d*) \+(\d+),?(\d*) @@$/
  while textPointer < text.length
    m = text[textPointer].match(patchHeader)
    throw new Error("Invalid patch string: " + text[textPointer])  unless m
    patch = new diff_match_patch.patch_obj()
    patches.push patch
    patch.start1 = parseInt(m[1], 10)
    if m[2] is ""
      patch.start1--
      patch.length1 = 1
    else if m[2] is "0"
      patch.length1 = 0
    else
      patch.start1--
      patch.length1 = parseInt(m[2], 10)
    patch.start2 = parseInt(m[3], 10)
    if m[4] is ""
      patch.start2--
      patch.length2 = 1
    else if m[4] is "0"
      patch.length2 = 0
    else
      patch.start2--
      patch.length2 = parseInt(m[4], 10)
    textPointer++
    while textPointer < text.length
      sign = text[textPointer].charAt(0)
      try
        line = decodeURI(text[textPointer].substring(1))
      catch ex
        
        # Malformed URI sequence.
        throw new Error("Illegal escape in patch_fromText: " + line)
      if sign is "-"
        
        # Deletion.
        patch.diffs.push [DIFF_DELETE, line]
      else if sign is "+"
        
        # Insertion.
        patch.diffs.push [DIFF_INSERT, line]
      else if sign is " "
        
        # Minor equality.
        patch.diffs.push [DIFF_EQUAL, line]
      else if sign is "@"
        
        # Start of next patch.
        break
      
      # Blank line?  Whatever.
      
      # WTF?
      else throw new Error("Invalid patch mode \"" + sign + "\" in: " + line)  unless sign is ""
      textPointer++
  patches


###
Class representing one patch operation.
@constructor
###
diff_match_patch.patch_obj = ->
  
  ###
  @type {!Array.<!diff_match_patch.Diff>}
  ###
  @diffs = []
  
  ###
  @type {?number}
  ###
  @start1 = null
  
  ###
  @type {?number}
  ###
  @start2 = null
  
  ###
  @type {number}
  ###
  @length1 = 0
  
  ###
  @type {number}
  ###
  @length2 = 0


###
Emmulate GNU diff's format.
Header: @@ -382,8 +481,9 @@
Indicies are printed as 1-based, not 0-based.
@return {string} The GNU diff string.
###
diff_match_patch.patch_obj::toString = ->
  coords1 = undefined
  coords2 = undefined
  if @length1 is 0
    coords1 = @start1 + ",0"
  else if @length1 is 1
    coords1 = @start1 + 1
  else
    coords1 = (@start1 + 1) + "," + @length1
  if @length2 is 0
    coords2 = @start2 + ",0"
  else if @length2 is 1
    coords2 = @start2 + 1
  else
    coords2 = (@start2 + 1) + "," + @length2
  text = ["@@ -" + coords1 + " +" + coords2 + " @@\n"]
  op = undefined
  
  # Escape the body of the patch with %xx notation.
  x = 0

  while x < @diffs.length
    switch @diffs[x][0]
      when DIFF_INSERT
        op = "+"
      when DIFF_DELETE
        op = "-"
      when DIFF_EQUAL
        op = " "
    text[x + 1] = op + encodeURI(@diffs[x][1]) + "\n"
    x++
  text.join("").replace /%20/g, " "


# Export these global variables so that they survive Google's JS compiler.
# In a browser, 'this' will be 'window'.
# Users of node.js should 'require' the uncompressed version since Google's
# JS compiler may break the following exports for non-browser environments.
this["diff_match_patch"] = diff_match_patch
this["DIFF_DELETE"] = DIFF_DELETE
this["DIFF_INSERT"] = DIFF_INSERT
this["DIFF_EQUAL"] = DIFF_EQUAL