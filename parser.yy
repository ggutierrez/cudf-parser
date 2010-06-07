/* $Id: parser.yy 48 2009-09-05 08:07:10Z tb $ -*- mode: c++ -*- */
/** \file parser.yy Contains the example Bison parser source */

%{ /*** C/C++ Declarations ***/
#include <boost/foreach.hpp>
#include <boost/variant/variant.hpp>
#include <boost/variant/get.hpp>
#include <boost/tuple/tuple.hpp>
#include <stdio.h>
#include <string>
#include <vector>

#include "cudf.h"
  
#define  foreach BOOST_FOREACH
  
  typedef boost::variant<vpkglist_t,list_vpkglist_t,Keep> propVariant;
  typedef boost::tuple<std::string,propVariant> propData;
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
  int  			     integerVal;
  std::string*		     stringVal;
  RelOp                        relopVal;
  Keep                          keepVal;
  class Vpkg*               vpkgVal;
  vpkglist_t*                 vpkglistVal;
  list_vpkglist_t*          listvpkglistVal;
  propVariant*             propVal;
  class CudfPackage*   pkgVal;
  class CudfDoc*         docVal;
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
%token <stringVal> 	STRING	        "string"
%token <stringVal>        PROPNAME  "property name"
%token <stringVal>        IDENT            "identifier"

%type <relopVal> relop
%type<keepVal> keepprop
%type<vpkgVal> vpkg
%type<vpkglistVal> vpkglist vpkglist2
%type<listvpkglistVal> vpkgorlist
%type<propVal> pkgprop
%type <pkgVal> package universe

%destructor { delete $$; } STRING
%destructor { delete $$; } PROPNAME
%destructor { delete $$; } IDENT
%destructor { delete $$; } vpkg
%destructor { delete $$; } vpkglist
%destructor { delete $$; } vpkglist2
%destructor { delete $$; } vpkgorlist
%destructor { delete $$; } package
%destructor { delete $$; } universe
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
	      }

propdefs : /* empty */
          | propdef
          | propdefs ',' propdef

preamble : PREAMBLE EOL PROPERTYKW propdefs
         {
	   std::cerr << "recognized preamble" << std::endl;
	 }

relop :
            REQ    {$$ = ROP_EQ;}
	  | RNEQ {$$ = ROP_NEQ;}
	  | RGT    {$$ = ROP_GT;}
	  | RGE    {$$ = ROP_GE;}
	  | RLT    {$$ = ROP_LT;}
	  | RLE    {$$ = ROP_LE;}
	  
vpkg : 
           IDENT {$$ = new Vpkg(*$1,ROP_NOP,0)}
           | IDENT relop INTEGER
	   {
	     $$ = new Vpkg(*$1,$2,$3);
	   }

vpkglist : 
         vpkg
         {
	   $$ = new vpkglist_t;
	   $$->push_back(*$1);
         }
         | vpkglist ',' vpkg
	 {
	   $$ = new vpkglist_t;
	   foreach(Vpkg v, *$1) {
	     $$->push_back(v);
	   }
	   $$->push_back(*$3);
	 }

vpkglist2 : 
          vpkg
         {
	   $$ = new vpkglist_t;
	   $$->push_back(*$1);	   
	 }
	 | vpkglist2 '|' vpkg
	 {
	   $$ = new vpkglist_t;
	   foreach(Vpkg& v, *$1) {
	     $$->push_back(v);
	   }
	   $$->push_back(*$3);
	 }

vpkgorlist : 
          /* empty */
         {
	   $$ = new list_vpkglist_t; 
	 }
         | vpkglist2
         {
	   $$ = new list_vpkglist_t;
	   $$->push_back(*$1);
         }
         | vpkgorlist ',' vpkglist2
	 {
	   $$ = new list_vpkglist_t;
	   foreach(vpkglist_t& v, *$1) {
	     $$->push_back(v);
	   }
	   $$->push_back(*$3);
	 }

propval :
         /* empty */
         | STRING
         | INTEGER
         | IDENT
              
keepprop :
                 KEEPNONE { $$ = KP_NONE; }
		 | KEEPVERSION { $$ = KP_VERSION; }
		 | KEEPPACKAGE { $$ = KP_PACKAGE; }
		 | KEEPFEATURE { $$ = KP_FEATURE; }

pkgprop :
          DEPENDSKW vpkgorlist EOL
          {
	    $$ = new propVariant;
	    *$$ = *$2;
	    //std::cout << "dependencies " <<  *$$ << std::endl;
          }
          | CONFLICTSKW vpkglist EOL
          {
	    $$ = new propVariant;
	    *$$ = *$2;
            //std::cout << "conflicts " << *$$ << std::endl;
          }
          | PROVIDESKW vpkglist EOL
          {
	    $$ = new propVariant;
	    *$$ = *$2;
            //std::cout << "provides" << *$$ << std::endl;
          }
          | KEEPKW keepprop EOL
	  {
	    $$ = new propVariant;
	    *$$ = $2;
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
		 CudfPackage *pkg = new CudfPackage;
		 pkg->name(*$2);
		 pkg->version($5);
		 //std::cout << "recognized package: " << *$2
		 //<< " version: " << $5 << std::endl;
		 $$ = pkg;
	       }

universe :
               package
	       {
		 //std::cerr << "recognized package " << *$1 << std::endl;
		 //driver.doc.
	       }
               | universe EOL package 
	       {
		 //std::cerr << "recognized package " << *$1 << std::endl;
		 //delete $1;
	       }


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
