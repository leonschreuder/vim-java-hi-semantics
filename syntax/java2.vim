" Vim syntax file
" Language:	Java
"
" If you've stumbled accross this and want to understand what it is doing
" you'd better not. I'm testing stuff out as I'm trying to build it, and I
" try to keep a record of what I've been doing by copy-pasting the stuff I've
" tried out. It is just like this rambling description, only worse.
" You might want to wait a bit before you try it out, till it gets more
" stable...
"
" JAVA2 I'm trying to replace the standard java highlighting here

"TODO:
"– In an interface the last item is also highlighted   BUG
"– Fields inside a method that has a parameter with the same name, are
"  overwritten and highlighted as a parameter. Try to exclude this behavior when
"  it is prepended by 'this.'

" don't use standard HiLink, it will not work with included syntax files
if version < 508
  command! -nargs=+ JavaHiLink hi link <args>
else
  command! -nargs=+ JavaHiLink hi def link <args>
endif


let s:preRunWindowState = winsaveview()

"--------------------------------------------------------------------------------
" Highlighting field names
"--------------------------------------------------------------------------------
function! HighlightFields()
python << EOF
import re
import vim


cb = vim.current.buffer


classStart = 0
classEnd = len(cb)

count = 0


for i, line in enumerate(cb):
	result = re.search('.*class', line)
	if result and result.group():
		classLine = i
		break


allResults = []
#for line in cb[classStart:classEnd]:
for line in cb:

	result = re.search('''
			(?:private|public|protected)\s	# Scope decleration
			(?:\S*?\s)*?		   			# up to 4 words
			(\S*?[^\s|;])					# a word (captured)
			(?:\s?=|;)						# optional a space and an equals followd by anything
											# a line-end character
		''', line, re.VERBOSE)
	if result:
		allResults.append(result.group(1))

for result in allResults:
	vim.command( 'syn match javaFields "\<' + result + '\>"')

EOF
endfunction

call HighlightFields()

"let fieldNamesList=[]
" Matches field definitions with a value (with an equals sign)
"silent! %s/\v(private|public|protected)\s(\S{-}\s)*(\S{-})\s\=\zs/\=add(fieldNamesList,submatch(3))[1:0]/g
"echo fieldNamesList


" Matches field definitions without a value (no equals sign)
" Every value is specified, as not to match lines that DO contain an equals sign...
"silent! %s/\v(private|public|protected)\s([a-zA-Z0-9_\.\[\]<>]{-}\s)*(\S{-});\zs/\=add(fieldNamesList,submatch(3))[1:0]/g
"echo fieldNamesList

" Adds every found fieldName to the 'javaFields' match group
"for fieldName in fieldNamesList
	"if fieldName != ""
		""execute 'syn match javaFields "\<' . fieldName . '\>"'
	"endif
"endfor

" add highlighting inside the javaTop cluster
syn cluster javaTop add=javaFields

" Highlight the javaFields as a 'Function' Group. This is blue with the
" solarised color scheme
hi def link javaFields		Function






"--------------------------------------------------------------------------------
" Helper functions for highlighting the parameters
"--------------------------------------------------------------------------------

fu! s:getMethodName(methodString)
	return split(a:methodString, '(')[0]
endfu

fu! s:getInsideBraces(stringWithBraces)
	return matchstr(a:stringWithBraces, '\v(\()\zs(.*)(\))@=')
endfu

fu! s:getParameterNames(stringWithParameters)
	let paramNames = []

	if match(a:stringWithParameters, ',') > 0
		let singleParamStringList = split(a:stringWithParameters, ',')

		for singleParamString in singleParamStringList
			call add(paramNames, s:getParamNameFromParamString(singleParamString))
		endfor
	elseif len(a:stringWithParameters) > 0
		call add(paramNames, s:getParamNameFromParamString(a:stringWithParameters))
	endif

	return paramNames
endfu

fu! s:getParamNameFromParamString(paramString)
		return split(a:paramString, '\v\s=\S{-}\s')[0]
endfu


"--------------------------------------------------------------------------------
" Highlighting method parameter names
"--------------------------------------------------------------------------------
function! HighlightParams()
python << EOF
import re
import vim

highlightParamsAsGroup = 'Type' #Statement
highlightVarAsGroup = 'Statement' #Underlined


def escapeMagic(string):
	charactersToEscape = '[]'

	for char in charactersToEscape:
		string = string.replace(char, '\\'+char)
	return string

'''
This method searches the supplied line for a method definition
and if one was found, it finds the method name and parameters
'''
def getMethodNameAndParamsFromLine(line):
	foundValuesDict = {}

	matchMethodDef = re.search(r'''
			(?:private|public|protected)\s # Scope decleration
			(?:\S*?\s)*?		   # up to 4 words
			(\S*?)\(				   # method name
			(.*?)\)				   	   # inbetween the ()
			(?:.*?{)
		''', line, re.VERBOSE)

	if matchMethodDef:

		methodName = matchMethodDef.group(1)
		inbetweenBraces = matchMethodDef.group(2)

		if len(inbetweenBraces) > 0:
			paramsList = []
			paramsGroups = re.split(',', inbetweenBraces)
			for currentGroup in paramsGroups:
				currentGroup = currentGroup.strip()

				splitGroup = re.split('\s', currentGroup)

				paramsList.append(splitGroup[-1])


			foundValuesDict['params'] = paramsList


		foundValuesDict['methodName'] = methodName


	return foundValuesDict


cb = vim.current.buffer
methodsToHighlight = []


bracketCount = 0
lookingForEndOf = None


'''
This loop finds the method start and end from the file
'''
for i, line in enumerate(cb):

	singleMethodDict = getMethodNameAndParamsFromLine(line)

	if not lookingForEndOf:
		if singleMethodDict:
			singleMethodDict['startLine'] = escapeMagic(line)
			singleMethodDict['startLineIndex'] = i

			bracketCount = 1
			lookingForEndOf = singleMethodDict['methodName']

			methodsToHighlight.append(singleMethodDict)

	else:
		oldBracketCount = bracketCount

		currentLine = line

		lineCommentSplit = re.split("//", line)
		if lineCommentSplit:
			currentLine = lineCommentSplit[0]

		openBracketsInLine = re.findall('{', currentLine)
		if openBracketsInLine:
			bracketCount = bracketCount + len(openBracketsInLine)

		closeBracketsInLine = re.findall('}', currentLine)
		if closeBracketsInLine:
			bracketCount = bracketCount - len(closeBracketsInLine)

		if bracketCount < oldBracketCount and oldBracketCount == 1:
			for method in methodsToHighlight:
				if method['methodName'] == lookingForEndOf:
					method['endingLine'] = line
					method['endingLineIndex'] = i
			lookingForEndOf = None

'''
this loop searches the methods for defined variables
'''
for method in methodsToHighlight:
	iStart = method['startLineIndex']
	iEnd = method['endingLineIndex']

	foundVars = []
	for line in cb[iStart:iEnd]:
		matchMethodDef = re.search(r'''
				(?:^\s*?)				# Indented beginning of the line
				(?!return)				# don't capture return statements
				(?:for\s*?)?			# Indented beginning of the line
				(?:\S+?)				# Class name
				(?:\s+?)				# 1 or more spaces
				([A-Za-z_]*?[^;])		# variableName (captured)
				(?:\s*?)				# 0 or more spaces
				(?:=|;|:)				# an equals, line end or colon (in for loops)
			''', line, re.VERBOSE)

		if matchMethodDef:
			foundVars.append(matchMethodDef.group(1))

	method['variables'] = foundVars


'''
The found methods and parameters are highlighted here
'''
for i, method in enumerate(methodsToHighlight):

	#Add every parameter to the matchGroup. Note: The group should only be contained
	#inside another group (which will be the method)
	hiParamsGroupName = 'parameter'+str(i)

	if 'params' in method:
		for param in method['params']:
			#Highlights the parameter, unless it is preceded by 'this.'
			vim.command('syn match ' + hiParamsGroupName + ' "\(this\.\)\@<!\<' + param + '\>" contained')

	vim.command('hi def link ' + hiParamsGroupName + ' ' + highlightParamsAsGroup)


	hiVarsGroupName = 'variable'+str(i)


	if 'variables' in method:
		for var in method['variables']:
			#Highlights the parameter, unless it is preceded by 'this.'
			vim.command('syn match ' + hiVarsGroupName + ' "\<' + var + '\>" contained')


	vim.command('hi def link ' + hiVarsGroupName + ' ' + highlightVarAsGroup)






	hiMethodGroupName = 'completeMethod'+str(i)

	vim.command( 'syn region ' + hiMethodGroupName
				+ ' start="^' + method['startLine'] + '"'
				+ ' end=+^' + method['endingLine'] + '+'
				+ ' contains=@javaTop,' + hiParamsGroupName +','+ hiVarsGroupName + ',javaFields')





EOF
endfunction

call HighlightParams()


"syn region completeMethodB  start=+calcHeatRequirement(+  end=+)+
"hi def link completeMethodB		Statement


"let methodWithParamsList=[]
"silent! %s/\v(private|public|protected)\s([_$a-zA-Z<>\[\]]{-}\s)*(\w{-}\((.{-})\))\zs/\=add(methodWithParamsList,submatch(3))[1:0]/g
"
"let i = 0
"for methodWithParams in methodWithParamsList
"	"Note: Because every method needs to highlight only their own fields,
"	"every match needs a unique match group (like javaParams1). That's what
"	"the 'i' is for.
"	let currentJavaParams = 'javaParams' . i
"	let currentCompleteMethod = 'completeMethod' . i
"
"	let paramsList = s:getParameterNames(s:getInsideBraces(methodWithParams))
"	"echo paramsList
"	
"
"	"Add every parameter to the matchGroup. Note: The group should only be contained
"	"inside another group (which will be the method)
"	for param in paramsList
"		"Highlights the parameter, unless it is preceded by 'this.'
"		execute 'syn match ' . currentJavaParams . ' "\(this\.\)\@<!\<' . param . '\>" contained'
"	endfor
"
"	let methodName = s:getMethodName(methodWithParams)
"
"	"This creates a region for this method only. The region starts with the
"	"method name (which is indented one length) and ends with the closing }
"	"The intentation is used to match the start&end and is exactly one indent
"	"execute 'syn region '.currentCompleteMethod.'  start=+^\v(\t| {' . &tabstop . '}).{-}' . methodName . '\(.{-}\).{-}\{+  end=+^\v(\t| {' . &tabstop . '})}+ contains=@javaTop,' . currentJavaParams . ',javaFields'
"
"	"DEBUG this highlighs the entire method-region for debugging
"	"hi def link completeMethod1		Statement 
"
"	" Highlight the javaParams as a 'Statement' Group. This is yellow with the
"	" solarised color scheme
"	"execute 'hi def link ' . currentJavaParams . '		Statement'
"
"	" DELETE ME Highlights keyword in entire file
"	" add highlighting inside the javaTop cluster
"	"execute 'syn cluster javaTop add=' . currentJavaParams
"
"	let i += 1
"endfor





"--------------------------------------------------------------------------------
" Normal syntax highlighting (from java.vim)
"--------------------------------------------------------------------------------

" Comments
syn keyword javaTodo		 contained TODO FIXME XXX

syn region  javaComment		 start="/\*"  end="\*/" contains=javaTodo,@Spell
syn match   javaLineComment	 "//.*" contains=javaTodo,@Spell

syn cluster javaTop add=javaComment,javaLineComment

JavaHiLink javaComment		Comment
JavaHiLink javaTodo			Todo


" String
syn match   javaSpecialChar	 contained "\\\([4-9]\d\|[0-3]\d\d\|[\"\\'ntbrf]\|u\x\{4\}\)"
syn region  javaString		start=+"+ end=+"+ end=+$+ contains=javaSpecialChar,javaSpecialError,@Spell
syn cluster javaTop add=javaString

JavaHiLink javaSpecialChar		javaString



delcommand JavaHiLink
call winrestview(s:preRunWindowState)



"--------------------------------------------------------------------------------
" Reference
"--------------------------------------------------------------------------------
" [1] search-replace trick to retreive stuff from the current buffer
"	http://stackoverflow.com/questions/9079561/how-to-extract-regex-matches-using-vim
"--------------------------------------------------------------------------------
