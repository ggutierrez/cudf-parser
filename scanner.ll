/* $Id: scanner.ll 44 2008-10-23 09:03:19Z tb $ -*- mode: c++ -*- */
/** \file scanner.ll Define the example Flex lexical scanner */

%{ /*** C/C++ Declarations ***/

#include <string>

#include "scanner.h"

/* import the parser's token type into a local typedef */
typedef example::Parser::token token;
typedef example::Parser::token_type token_type;

/* By default yylex returns int, we use token_type. Unfortunately yyterminate
 * by default returns 0, which is not of token_type. */
#define yyterminate() return token::END

/* This disables inclusion of unistd.h, which is not available under Visual C++
 * on Win32. The C++ scanner uses STL streams instead. */
#define YY_NO_UNISTD_H

%}

/*** Flex Declarations and Options ***/

/* enable c++ scanner class generation */
%option c++

/* change the name of the scanner class. results in "ExampleFlexLexer" */
%option prefix="Example"

/* the manual says "somewhat more optimized" */
%option batch

/* enable scanner to generate debug output. disable this for release
 * versions. */
/* %option debug */

/* no support for include files is planned */
%option yywrap nounput 

/* enables the use of start condition stacks */
%option stack

/* exclusive start conditions.
   keep is exclusive because its possible values may colide with package names.
 */
%x comment ccomment keep
/* The following paragraph suffices to track locations accurately. Each time
 * yylex is invoked, the begin position is moved onto the end position. */
%{
#define YY_USER_ACTION  yylloc->columns(yyleng);
%}

%% /*** Regular Expressions Part ***/

 /* code to place at the beginning of yylex() */
%{
    // reset location
    yylloc->step();
%}

 /*** BEGIN EXAMPLE - Change the example lexer rules below ***/

true {
  yylval->boolVal = true;
  return token::BOOL;
}

false {
  yylval->boolVal = false;
  return token::BOOL;
}

preamble: {
  return token::PREAMBLE; 
}

property: { 
  return token::PROPERTYKW; 
}

package: {
 return token::PACKAGEKW; 
}

version: { 
  return token::VERSIONKW;
}

depends: { 
  return token::DEPENDSKW;
}

conflicts: {
  return token::CONFLICTSKW;
}

provides: {
  return token::PROVIDESKW;
}

installed: {
  return token::INSTALLEDKW;
}

keep: {
  BEGIN(keep);
  return token::KEEPKW;
}

<keep>version {
  BEGIN(INITIAL);
  return token::KEEPVERSION;
}

<keep>package {
  BEGIN(INITIAL);
  return token::KEEPPACKAGE;
}

<keep>feature {
  BEGIN(INITIAL);
  return token::KEEPFEATURE;
}

<keep>none {
  BEGIN(INITIAL);
  return token::KEEPNONE;
}

request:[^\n]* {
  return token::REQUEST;
}

upgrade: {
  return token::UPGRADE;
}

install: {
  return token::INSTALL;
}

remove: {
  return token::REMOVE;
}

>=  { return token::RGE; }
>   { return token::RGT; }
\<  { return token::RLT; }
\<= { return token::RLE; }
!=  { return token::RNEQ; }
=   { return token::REQ; }


[0-9]+ {
    yylval->integerVal = atoi(yytext);
    return token::INTEGER;
}


[a-zA-z][A-Za-z0-9_@()~%/+\.]+":" {
	/* property name is an identifier followed by a colon */
    yylval->stringVal = new std::string(yytext, yyleng);
    return token::PROPNAME;
}

[A-Za-z0-9_@()~%/+\.\-:]+ {
	/* from now on an identifier and a package name are considered
		 the same thing.
		*/
    yylval->stringVal = new std::string(yytext, yyleng);
    return token::IDENT;
}

 /* gobble up white-spaces */
[ \t\r]+ {
    yylloc->step();
}

 /* gobble up end-of-lines */
\n {
  yylloc->lines(yyleng); yylloc->step();
  return token::EOL;
}

<INITIAL># {
  BEGIN(comment);
}

<comment>[^\n]*

<comment>\n {
  yylloc->lines(yyleng); yylloc->step();
  BEGIN(INITIAL);
}

<INITIAL>"/*" { BEGIN(ccomment); }
<ccomment>"*/" { BEGIN(INITIAL); }
<ccomment>[^*\n]+
<ccomment>"*"
<ccomment>\n {
  yylloc->lines(yyleng); yylloc->step();
 }


 /* pass all other characters up to bison */
. {
    return static_cast<token_type>(*yytext);
}

 /*** END EXAMPLE - Change the example lexer rules above ***/

%% /*** Additional Code ***/

namespace example {

Scanner::Scanner(std::istream* in,
		 std::ostream* out)
    : ExampleFlexLexer(in, out)
{
}

Scanner::~Scanner()
{
}

void Scanner::set_debug(bool b)
{
    yy_flex_debug = b;
}

}

/* This implementation of ExampleFlexLexer::yylex() is required to fill the
 * vtable of the class ExampleFlexLexer. We define the scanner's main yylex
 * function via YY_DECL to reside in the Scanner class instead. */

#ifdef yylex
#undef yylex
#endif

int ExampleFlexLexer::yylex()
{
    std::cerr << "in ExampleFlexLexer::yylex() !" << std::endl;
    return 0;
}

/* When the scanner receives an end-of-file indication from YY_INPUT, it then
 * checks the yywrap() function. If yywrap() returns false (zero), then it is
 * assumed that the function has gone ahead and set up `yyin' to point to
 * another input file, and scanning continues. If it returns true (non-zero),
 * then the scanner terminates, returning 0 to its caller. */

int ExampleFlexLexer::yywrap()
{
    return 1;
}
