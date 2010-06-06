/* $Id: parser.yy 48 2009-09-05 08:07:10Z tb $ -*- mode: c++ -*- */
/** \file parser.yy Contains the example Bison parser source */

%{ /*** C/C++ Declarations ***/

#include <stdio.h>
#include <string>
#include <vector>

#include "expression.h"

%}

/*** yacc/bison Declarations ***/

/* Require bison 2.3 or later */
%require "2.3"

/* add debug output code to generated parser. disable this for release
 * versions. */
%debug

/* start symbol is named "start" */
%start start

/* write out a header file containing the token defines */
%defines

/* use newer C++ skeleton file */
%skeleton "lalr1.cc"

/* namespace to enclose parser in */
%name-prefix="example"

/* set the parser's class identifier */
%define "parser_class_name" "Parser"

/* keep track of the current position within the input */
%locations
%initial-action
{
    // initialize the initial location object
    @$.begin.filename = @$.end.filename = &driver.streamname;
};

/* The driver is passed by reference to the parser and to the scanner. This
 * provides a simple but effective pure interface, not relying on global
 * variables. */
%parse-param { class Driver& driver }

/* verbose error messages */
%error-verbose

 /*** BEGIN EXAMPLE - Change the example grammar's tokens below ***/

%union {
    int  			integerVal;
    std::string*		stringVal;
    class CalcNode*		calcnode;
}

%token			END					0		"end of file"
%token			EOL							"end of line"

%token			PREAMBLE            "'preamble:'"
%token			PROPERTYKW      "'property:'"

%token			PACKAGEKW        "'package:'"
%token			VERSIONKW          "'version:'"
%token			DEPENDSKW         "'depends:'"
%token			CONFLICTSKW     "'conflicts:'"
%token			PROVIDESKW       "'provides:'"
%token                    KEEPKW                 "'keep:'"
%token                    KEEPPACKAGE    "'package'"
%token                    KEEPVERSION     "'version'"
%token                    KEEPFEATURE    "'feature'"
%token                    KEEPNONE           "'none'"
%token			REQUEST               "'request:'"
%token			UPGRADE              "'upgrade:'"
%token			INSTALL                "'install:'"
%token			REMOVE                "'remove:'"

%token			REQ		"="
%token			RNEQ		"!="
%token			RGT		">"
%token			RGE		">="
%token			RLT		"<"
%token			RLE		"<="

%token <integerVal> 	INTEGER      "integer"
%token <stringVal> 	STRING		"string"
%token <stringVal>      PROPNAME    "property name"
%token <stringVal>      IDENT              "identifier"

%destructor { delete $$; } STRING
%destructor { delete $$; } PROPNAME
%destructor { delete $$; } IDENT
%{

#include "driver.h"
#include "scanner.h"

/* this "connects" the bison parser in the driver to the flex scanner class
 * object. it defines the yylex() function call to pull the next token from the
 * current lexer object of the driver context. */
#undef yylex
#define yylex driver.lexer->lex

%}

%% /*** Grammar Rules ***/
 
propinit : /* empy */
          | REQ '[' INTEGER ']'

propdef :
              PROPNAME  IDENT propinit
	      {
		//std::cout << "propdef " << *$1 << std::endl
		//<< "type " << *$2 << std::endl;
	      }

propdefs : /* empty */
          | propdef
          | propdefs ',' propdef

preamble : PREAMBLE EOL PROPERTYKW propdefs
         {
	   std::cerr << "recognized preamble" << std::endl;
	 }

relop : REQ
      | RNEQ
      | RGT
      | RGE
      | RLT
      | RLE

vpkg : IDENT
     | IDENT relop INTEGER
     {
     //std::cerr << "versioned constraint: " << *$1 << " ** " << $3 << std::endl;
     }

vpkglist : 
         vpkg
         {
         //std::cout << "recog vpkglist" << std::endl;
         }
         | vpkglist ',' vpkg

vpkglist2 : 
          vpkg
         {
	   
	 }
	 | vpkglist2 '|' vpkg

vpkgorlist : 
          /* empty */
         | vpkglist2
         {
         //std::cout << "recog vpkglist2" << std::endl;
         }
         | vpkgorlist ',' vpkglist2

propval :
         /* empty */
         | STRING
         | INTEGER
         | IDENT
              
keepprop :
                 KEEPNONE
		 | KEEPVERSION
		 | KEEPPACKAGE
		 | KEEPFEATURE

pkgprop :
          DEPENDSKW vpkgorlist EOL
          {
            //std::cout << "dependencies" << std::endl;
          }
          | CONFLICTSKW vpkglist EOL
          {
            //std::cout << "conflicts" << std::endl;
          }
          | PROVIDESKW vpkglist EOL
          {
            //std::cout << "provides" << std::endl;
          }
          | KEEPKW keepprop EOL
	  {
	  }
          |PROPNAME propval EOL
          {
          //std::cerr << "**property** '" << *$1 << "'" << std::endl;
          }
        
pkgprops :
                 /*empty */
                | pkgprop
                 {
		   //std::cerr << "package property" << std::endl;
		 }
               | pkgprops pkgprop
	       {
	       }

package : 
               PACKAGEKW IDENT EOL
	       VERSIONKW INTEGER EOL
	       pkgprops
	       {
		 //std::cout << "recognized package: " << *$2
		 //<< " version: " << $5 << std::endl;
	       }

universe :
               package
	       {
	         //std::cerr << "recognized package" << std::endl;
	       }
               | universe EOL package 


reqst :
         INSTALL vpkglist EOL
         | UPGRADE vpkglist EOL
         | REMOVE vpkglist EOL
	 
reqlist:
        reqst
        | reqlist reqst

request :
             REQUEST EOL reqlist

start	:
        preamble EOL EOL universe EOL EOL request
        {
          std::cout << "finished" << std::endl;
	}

%% /*** Additional Code ***/

void example::Parser::error(const Parser::location_type& l,
			    const std::string& m)
{
  driver.error(l, m);
}
