" Vim syntax file
" Language:	Java
"
" If you've stumbled accross this and want to understand what it is doing
" you'd better not. I'm testing stuff out as I'm trying to build it, and I
" try to keep a record of what I've been doing by copy-pasting the stuff I've
" tried out. It is just like this rambling description, only worse.
" You might want to wait a bit before you try it out, till it gets more
" stable...

"TODO:
"– In an interface the last item is also highlighted   BUG
"– Fields inside a method that has a parameter with the same name, are
"  overwritten and highlighted as a parameter. Try to exclude this behavior when
"  it is prepended by 'this.'


"--------------------------------------------------------------------------------
" Highlighting field names
"--------------------------------------------------------------------------------

let fieldNamesList=[]
" Matches field definitions with a value (with an equals sign)
silent! %s/\v(private|public|protected)\s(\S{-}\s)*(\w{-})\s\=\zs/\=add(fieldNamesList,submatch(3))[1:0]/g

" Matches field definitions without a value (no equals sign)
silent! %s/\v(private|public|protected)\s(\S{-}\s)*(\w{-});\zs/\=add(fieldNamesList,submatch(3))[1:0]/g

" Adds every found fieldName to the 'javaFields' match group
for fieldName in fieldNamesList
	if fieldName != ""
		execute 'syn match javaFields "' . fieldName . '"'
	endif
endfor

"syn cluster javaTop add=javaFields "<< Can I delete this? Does seem to work fine without it

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
		return split(a:paramString, '\v\s=\w{-}\s')[0]
endfu


"--------------------------------------------------------------------------------
" Highlighting method parameter names
"--------------------------------------------------------------------------------
let methodWithParamsList=[]
silent! %s/\v(private|public|protected)\s([_$a-zA-Z<>]{-}\s)*(\w{-}\((.{-})\))\zs/\=add(methodWithParamsList,submatch(3))[1:0]/g

let i = 0
for methodWithParams in methodWithParamsList
	"Note: Because every method needs to highlight only their own fields,
	"every match needs a unique match group (like javaParams1). That's what
	"the 'i' is for.

	let paramsList = s:getParameterNames(s:getInsideBraces(methodWithParams))

	"Add every parameter to the matchGroup. Note: The group can only be contained
	"inside another group (which will be the method)
	for param in paramsList
		"execute 'syn match javaParams' . i . ' "\(this\)\@!' . param . '" contained' "<< Doesn't work. Why not?
		execute 'syn match javaParams' . i . ' "\<' . param . '\>" contained'
	endfor

	let methodName = s:getMethodName(methodWithParams)

	"This creates a region for this method only. The region starts with the
	"method name (which is indented one length) and ends with the closing }
	execute 'syn region completeMethod  start=+^\v(\t| {' . &tabstop . '}).{-}' . methodName . '\(.{-}\).{-}\{+  end=+}+ contains=javaScopeDecl,javaType,javaStorageClass,@javaClasses,javaParams' . i . ',javaFields'

	"DEBUG this highlighs the entire method-region for debugging
	"hi def link completeMethod		Statement 

	" Highlight the javaParams as a 'Statement' Group. This is yellow with the
	" solarised color scheme
	execute 'hi def link javaParams' . i . '		Statement'

	let i += 1
endfor


"--------------------------------------------------------------------------------
" Reference
"--------------------------------------------------------------------------------
" [1] search-replace trick to retreive stuff from the current buffer
"	http://stackoverflow.com/questions/9079561/how-to-extract-regex-matches-using-vim
"--------------------------------------------------------------------------------
