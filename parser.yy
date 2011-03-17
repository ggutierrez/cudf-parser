/* $Id: parser.yy 48 2009-09-05 08:07:10Z tb $ -*- mode: c++ -*- */
/** \file parser.yy Contains the example Bison parser source */

%code requires { /*** C/C++ Declarations ***/
#include <boost/foreach.hpp>
#include <boost/variant/variant.hpp>
#include <boost/variant/get.hpp>
#include <boost/tuple/tuple.hpp>
#include <stdio.h>
#include <string>
#include <vector>
#include <map>

#include "cudf.h"
  
#define  foreach BOOST_FOREACH
  
  using std::string;
  using std::map;

  typedef boost::variant<vpkglist_t,list_vpkglist_t,Keep,std::string,int,bool> propVariant;
  typedef boost::tuple<string,propVariant> propData;
  typedef map<string,propVariant> pkgProps;
}

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
  bool               boolVal;
  int  			     integerVal;
  std::string*		 stringVal;
  RelOp              relopVal;
  Keep               keepVal;
  class Vpkg*        vpkgVal;
  vpkglist_t*        vpkglistVal;
  list_vpkglist_t*   listvpkglistVal;
  propData*          propVal;
  pkgProps*          propsVal;
  propVariant*	     propertyVal;
}

%token			END					0		"end of file"
%token			EOL							"end of line"

%token			PREAMBLE                    "'preamble:'"
%token			PROPERTYKW                  "'property:'"

%token			PACKAGEKW                   "'package:'"
%token			VERSIONKW                   "'version:'"
%token			DEPENDSKW                   "'depends:'"
%token			CONFLICTSKW                 "'conflicts:'"
%token			PROVIDESKW                  "'provides:'"
%token			INSTALLEDKW                 "'installed:'"
%token      KEEPKW                      "'keep:'"
%token      KEEPPACKAGE                 "'package'"
%token      KEEPVERSION                 "'version'"
%token      KEEPFEATURE                 "'feature'"
%token      KEEPNONE                    "'none'"
%token			REQUEST                     "'request:'"
%token			UPGRADE                     "'upgrade:'"
%token			INSTALL                     "'install:'"
%token			REMOVE                      "'remove:'"

%token			REQ		"="
%token			RNEQ  "!="
%token			RGT		">"
%token			RGE		">="
%token			RLT		"<"
%token			RLE		"<="

%token <boolVal>        BOOL         "boolean ('true' or 'false')"
%token <integerVal>     INTEGER      "integer"
%token <stringVal> 	    STRING	     "string"
%token <stringVal>      PROPNAME     "property name"
%token <stringVal>      IDENT        "identifier"

%type <relopVal> relop
%type<keepVal> keepprop
%type<vpkgVal> vpkg
%type<vpkglistVal> vpkglist vpkglist2
%type<listvpkglistVal> vpkgorlist
%type<propVal> pkgprop
%type<propsVal> pkgprops
%type<propertyVal> propval
%type <pkgVal> package universe

%destructor { delete $$; } STRING
%destructor { delete $$; } PROPNAME
%destructor { delete $$; } IDENT
%destructor { delete $$; } vpkg
%destructor { delete $$; } vpkglist
%destructor { delete $$; } vpkglist2
%destructor { delete $$; } vpkgorlist
%destructor { delete $$; } pkgprop
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

propinit :
  /* empy */
  | REQ '[' INTEGER ']'

propdef :
  PROPNAME IDENT propinit
  {
    (void)$2;
    (void)$1;
  }

propdefs : /* empty */
  | propdef
  | propdefs ',' propdef

preamble : PREAMBLE EOL PROPERTYKW propdefs
  {
    //std::cerr << "recognized preamble" << std::endl;
  }

relop :
    REQ    {$$ = ROP_EQ;}
	  | RNEQ {$$ = ROP_NEQ;}
	  | RGT    {$$ = ROP_GT;}
	  | RGE    {$$ = ROP_GE;}
	  | RLT    {$$ = ROP_LT;}
	  | RLE    {$$ = ROP_LE;}
	  
vpkg : 
IDENT {$$ = new Vpkg(*$1,ROP_NOP,0);}
    |IDENT relop INTEGER
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
    {
      assert(false);
      $$ = new propVariant;
    }
    |INTEGER  { $$ = new propVariant($1); }
    | IDENT   { $$ = new propVariant(*$1); }
		| BOOL    { $$ = new propVariant($1); }
              
keepprop :
    KEEPNONE      { $$ = KP_NONE; }
		| KEEPVERSION { $$ = KP_VERSION; }
    | KEEPPACKAGE { $$ = KP_PACKAGE; }
		| KEEPFEATURE { $$ = KP_FEATURE; }

pkgprop :
    DEPENDSKW vpkgorlist EOL
    {
      $$ = new propData("_deps",*$2);
    }
    | CONFLICTSKW vpkglist EOL
    {
      $$ = new propData("_confs",*$2);
    }
    | PROVIDESKW vpkglist EOL
    {
      $$ = new propData("_pvds",*$2);
    }
    | KEEPKW keepprop EOL
    {
			$$ = new propData("_keep",$2);
    }
    | INSTALLEDKW BOOL EOL
    {
      $$ = new propData("_installed",$2);
    }
    |PROPNAME propval EOL
    {
			$$ = new propData(*$1,*$2);
    }
        
pkgprops :
    /*empty */
    {
      $$ = new pkgProps;
    }
    | pkgprop
    {
      $$ = new pkgProps;
      $$->insert(std::make_pair($1->get<0>(),$1->get<1>()));
      assert($$->size() == 1);
    }
    | pkgprops pkgprop
    {
      $$ = new pkgProps(*$1);
      $$->insert(std::make_pair($2->get<0>(),$2->get<1>()));
      assert($$->size() == $1->size() + 1);
    }

package : 
    PACKAGEKW IDENT EOL VERSIONKW INTEGER EOL pkgprops
    {
      /* This rule does not return, it just access the document an register
          the new package in the list. */
				
      CudfPackage pkg;
      pkg.pk_info.get<5>() = *$2;
      pkg.pk_info.get<6>() = $5;
      
      //std::cout << "size: " << $7->size() << std::endl;
      pkgProps *props = $7;
      //typedef std::pair<std::string,propVariant> data_t;
      //foreach (const data_t& d, *$7) {
      //	std::cout << d.first << std::endl;
      //}
      if (props->count("_pvds") > 0) {
        vpkglist_t& pvds = boost::get<vpkglist_t>(props->at("_pvds"));
        pkg.pk_info.get<3>() = pvds;
      }
      if (props->count("_confs") > 0) {
        vpkglist_t& cnfs = boost::get<vpkglist_t>(props->at("_confs"));
        pkg.pk_info.get<2>() = cnfs;
      }
      if (props->count("_deps") > 0) {
        list_vpkglist_t& deps = boost::get<list_vpkglist_t>(props->at("_deps"));
        pkg.pk_info.get<4>() = deps;
      }
      if (props->count("_keep") > 0) {
        std::cerr << "**KEEP**" << std::endl;
        Keep k = boost::get<Keep>(props->at("_keep"));
        pkg.pk_info.get<0>() = k;          
      } else {
          pkg.pk_info.get<0>() = KP_NONE;          
      }
      if (props->count("_installed") > 0) {
        bool i = boost::get<bool>(props->at("_installed"));
        pkg.pk_info.get<1>() = i;
        //std::cout << "installed property found for package " << *$2 << std::endl;
      } else {
        pkg.pk_info.get<1>() = false;
      }
      
      // finally add the new created package
      driver.doc.addPackage(pkg);
    }

universe :
    package
    | universe EOL package 

reqst :
    INSTALL vpkglist EOL
    {
      driver.doc.addInstall(*$2);
    }
    | UPGRADE vpkglist EOL
    {
      driver.doc.addUpgrade(*$2);
    }
    | REMOVE vpkglist EOL
    {
      driver.doc.addRemove(*$2);
    }
  
reqlist:
    reqst
    | reqlist reqst

request :
    REQUEST EOL reqlist

start	:
    preamble EOL EOL universe EOL EOL request
    {

    }

%% /*** Additional Code ***/

void example::Parser::error(const Parser::location_type& l, const string& m)
{	
  driver.error(l, m);
}
