" Vim syntax file
" Language:	Java
"
" If you've stumbled accross this and want to understand what it is doing
" you'd better not. I'm testing stuff out as I'm trying to build it, and I
" try to keep a record of what I've been doing by copy-pasting the stuff I've
" tried out. It is just like this rambling description, only worse.
" You might want to wait a bit before you try it out, till it gets more
" stable...



" The field search expression
"\v((private|public).*)@<=(\S*){1}(\s\=)@=


" Direclty highlighs the fields
"----------------------------------------
"syn match  javaFuncDef "\v((private|public).*)@<=(\S*)(\s\=)@="
"hi def link javaFuncDef		Function



"successfully highlights mDuplicateView and mOriginal in the file
"----------------------------------------
"let someList = ['mDuplicateView', 'mOriginal']
"for s:var in someList
	"execute 'syn keyword javaFields ' . s:var
"endfor
"hi def link javaFields		Function





" Highlights the fields using search-replace trick to get the fields
" http://stackoverflow.com/questions/9079561/how-to-extract-regex-matches-using-vim
"----------------------------------------
" refrence
"%s/\<case\s\+\(\w\+\):\zs/\=add(t,submatch(1))[1:0]/g

let t=[]
" Matches field definitions with an equals sign
silent! %s/\v(private|public|protected)\s(\S{-}\s)*(\w{-})\s\=\zs/\=add(t,submatch(3))[1:0]/g

" Matches field definitions without equals sign
"BUG: In an interface the last item is also highlighted
silent! %s/\v(private|public|protected)\s(\S{-}\s)*(\w{-});\zs/\=add(t,submatch(3))[1:0]/g


"let p=[]
"silent! %s/\v(private|public|protected)\s(\S{-}\s)*\w{-}\((\w{-}\s(\w{-}),=)\)\zs/\=add(p,submatch(4))[1:0]/g
"echo p

for s:var in t
	if s:var != ""
		execute 'syn match javaFields "' . s:var . '"'
	endif
endfor

syn cluster javaTop add=javaFields
hi def link javaFields		Function

"TODO: Tryout pandocImageCaption color
"and highlight local fields as well


" Directly loads the individual parameters per method, but only gets the last
" one form multiple parameters
"--------------------------------------------------------------------------------
"let p=[]
"silent! %s/\v(private|public|protected)\s(\S{-}\s)*\w{-}\((\w{-}\s(\w{-}),=)\)\zs/\=add(p,submatch(4))[1:0]/g

"for s:var in p
	"if s:var != ""
		"execute 'syn match javaParams "' . s:var . '"'
	"endif
"endfor


"syn cluster javaTop add=javaParams
"hi def link javaParams		Statement
" This works, but for the whole file. Research how I can search this within a method definition, and group it inside the method





fu! s:getMethodName(methodString)
	return split(a:methodString, '(')[0]
endfu

fu! s:getInsideBraces(stringWithBraces)
	return matchstr(a:stringWithBraces, '\v(\()\zs(.*)(\))@=')
endfu

fu! s:getParameters(stringWithParameters)
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
" Getting the method names and the paramater names
"--------------------------------------------------------------------------------
let matches=[]
"silent! %s/\v(private|public|protected)\s(\w{-}\s)*(\w{-}\((.{-})\))\zs/\=add(matches,submatch(3))[1:0]/g
silent! %s/\v(private|public|protected)\s([_$a-zA-Z<>]{-}\s)*(\w{-}\((.{-})\))\zs/\=add(matches,submatch(3))[1:0]/g

let i = 0
for singleMatch in matches
	"Because every method needs to highlight only their own fields, every
	"match needs a unique name (like javaParams1)

	let paramsList = s:getParameters(s:getInsideBraces(singleMatch))
	echo paramsList
	for param in paramsList
		execute 'syn match javaParams' . i . ' "\<' . param . '\>" contained'
	endfor

	"DEBUG This uses a specified field and searches for a specified method
	"syntax keyword singleField    context    contained
	"syn region completeMethod  start=+^\(\t\| \{8\}\).\{-}getResoureIdForImage(.\{-})\s\{-}{+  end=+}+ contains=javaScopeDecl,javaType,javaStorageClass,@javaClasses,singleField
	"hi def link singleField		Statement

	let methodName = s:getMethodName(singleMatch)
	execute 'syn region completeMethod  start=+^\v(\t| {' . &tabstop . '}).{-}' . methodName . '\(.{-}\).{-}\{+  end=+}+ contains=javaScopeDecl,javaType,javaStorageClass,@javaClasses,javaParams' . i . ',javaFields'

	"DEBUG highlighs the entire method
	"hi def link completeMethod		Statement 
	hi def link javaParams		Statement
	execute 'hi def link javaParams' . i . '		Statement'

	let i += 1
endfor

"--------------------------------------------------------------------------------
" Have to find a way to get the a complete method body including the paramaters
" as a group
"--------------------------------------------------------------------------------
"syn region completeMethod start=+^\(\t\| \{8\}\)[$_a-zA-Z][$_a-zA-Z0-9_. \[\]]*([^-+*/()]*,\s*+ end=+}+ contains=javaScopeDecl,javaType,javaStorageClass,@javaClasses
"syn region javaFuncDef start=+^\(\t\| \{8\}\)[$_a-zA-Z][$_a-zA-Z0-9_. \[\]]*([^-+*/()]*,\s*+ end=+)+ contains=javaScopeDecl,javaType,javaStorageClass,@javaClasses
"syn region completeMethod  start=+^\(\t\| \{8\}\)[$_a-zA-Z][$_a-zA-Z0-9_. \[\]]*([^-+*/()]*,\s*)\s*{+  end=+}+ contains=javaScopeDecl,javaType,javaStorageClass,@javaClasses

" WORKS: highlights entire method
"syn region completeMethod  start=+^\(\t\| \{8\}\).\{-}(.\{-})\s\{-}{+  end=+}+ contains=javaScopeDecl,javaType,javaStorageClass,@javaClasses
"hi def link completeMethod		Statement


" ALSO WORKS: I'm on a roll today
"syntax keyword singleMethod    sourceView    contained
"syn region completeMethod  start=+^\(\t\| \{8\}\).\{-}performTransitionNext(.\{-})\s\{-}{+  end=+}+ contains=javaScopeDecl,javaType,javaStorageClass,@javaClasses,singleMethod
"hi def link singleMethod		Statement



