/*
 [The "BSD licence"]
 Copyright (c) 2003-2009 Terence Parr
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. The name of the author may not be used to endorse or promote products
    derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/** Match a group of template definitions beginning
 *  with a group name declaration.  Templates are enclosed
 *  in double-quotes or <<...>> quotes for multi-line templates.
 *  Template names have arg lists that indicate the cardinality
 *  of the attribute: present, optional, zero-or-more, one-or-more.
 *  Here is a sample group file:

	group nfa;

	// an NFA has edges and states
	nfa(states,edges) ::= <<
	digraph NFA {
	rankdir=LR;
	<states; separator="\\n">
	<edges; separator="\\n">
	}
	>>

	state(name) ::= "node [shape = circle]; <name>;"

 */
grammar Group;

@header {
package org.stringtemplate;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.LinkedHashMap;
}

@lexer::header {
package org.stringtemplate;
}

@members {
protected STGroup group;
}

group returns[STGroup group]
@init {
this.group = $group = new STGroup();
}
	:	'group' name=ID {$group.name = $name.text;}
		( ':' s=ID {$group.supergroup = $s.text;} )?
	    ( 'implements' i+=ID (',' i+=ID )* {$group.interfaces=toStrings($i);} )?
	    ';'
	    ( templateDef | mapDef )+
    ;

templateDef
@init {
    String template=null;
}
	:	(	'@' ID '.' region=ID
		|	name=ID 
		)
	    '(' formalArgs? ')' '::='
	    (	STRING     {template=$STRING.text;
	    				template = template.substring(1, template.length()-1);}
	    |	BIGSTRING  {template=$BIGSTRING.text;
						template = template.substring(2, template.length()-2);}
	    )
	    {
	    group.defineTemplate($name.text, $formalArgs.args, template);
	    }
	|   alias=ID '::=' target=ID	    
	;

formalArgs returns[LinkedHashMap<String,FormalArgument> args]
@init {$args = new LinkedHashMap<String,FormalArgument>();}
    :	formalArg[$args] ( ',' formalArg[$args] )*
	;

formalArg[LinkedHashMap<String,FormalArgument> args]
@init {String defvalue = null;}
	:	ID
		(	'=' STRING				{defvalue = $STRING.text;}
		|	'=' ANONYMOUS_TEMPLATE	{defvalue = $ANONYMOUS_TEMPLATE.text;}
		)?
		{$args.put($ID.text, new FormalArgument($ID.text, defvalue));}
    ;

/*
suffix returns [int cardinality=FormalArgument.REQUIRED]
    :   OPTIONAL 
    |   STAR     
    |   PLUS     
	|
    ;
    */

mapDef
	:	name=ID '::=' m=map
	;

map returns [Map mapping=new HashMap()]
	:   '[' mapPairs[mapping] ']'
	;
	
mapPairs[Map mapping]
    : keyValuePair[mapping] (',' keyValuePair[mapping])*
      (',' defaultValuePair[mapping])?
    | defaultValuePair[mapping] 
    ;	
	
defaultValuePair[Map mapping]
	:	'default' ':' v=keyValue        
	;

keyValuePair[Map mapping]
	:	key=STRING ':' v=keyValue 
	;

keyValue returns [ST value=null]
	:	s1=BIGSTRING	
	|	s2=STRING		
	|	k=ID
	|					
	;

ID
	:	('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'-'|'_')*
	;

STRING
	:	'"' ( '\\' '"' | '\\' ~'"' | ~('\\'|'"') )* '"'
	;

BIGSTRING
	:	'<<'
		(	options {greedy=false;}
		:	'\\' '>'  // \> escape
		|	'\\' ~'>'
		|	~'\\'
		)*
        '>>'
	;

ANONYMOUS_TEMPLATE
    :    '{'  { new Chunkifier(input, '<', '>').matchBlock(); }
    ;

/*
ANONYMOUS_TEMPLATE
	:	'{'
		(	'\\' '}'   // \} escape
		|	'\\' ~'}'
		|	~('\\'|'}')
		)*
	    '}'
	;
*/

COMMENT
    :   '/*' ( options {greedy=false;} : . )* '*/' {skip();}
    ;

LINE_COMMENT
    :	'//' ~('\n'|'\r')* '\r'? '\n' {skip();}
    ;

WS  :	(' '|'\r'|'\t'|'\n') {skip();} ;
