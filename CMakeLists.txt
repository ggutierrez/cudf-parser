##
##  Main authors:
##     Yves Jaradin <yves.jaradin@uclouvain.be>
##     Gustavo Gutierrez <gutierrez.gustavo@uclouvain.be>
##
##  Copyright:
##     Yves Jaradin, 2010
##     Gustavo Gutierrez, 2010
##
##  Last modified:
##     $Date$ by $Author$
##     $Revision$
##
##
##  Permission is hereby granted, free of charge, to any person obtaining
##  a copy of this software and associated documentation files (the
##  "Software"), to deal in the Software without restriction, including
##  without limitation the rights to use, copy, modify, merge, publish,
##  distribute, sublicense, and/or sell copies of the Software, and to
##  permit persons to whom the Software is furnished to do so, subject to
##  the following conditions:
##
##  The above copyright notice and this permission notice shall be
##  included in all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
##  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
##  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
##  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
##  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
##  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
##  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
##
##

# Example call:
#
# cmake -DCMAKE_BUILD_SYSTEM=Debug \
#       -DCMAKE_PREFIX_PATH="/opt/local/"
#       ~/Downloads/PIPsolvers/ccp-kcudf
#

cmake_minimum_required (VERSION 2.6)

project (CudfParser)
set(DS_VERSION "0.1")

set(REQ_BOOST_LIBS)
set(Boost_USE_STATIC_LIBS  ON)
find_package(Boost 1.36 REQUIRED COMPONENTS ${REQ_BOOST_LIBS})
message(STATUS "Boost path: ${Boost_INCLUDE_DIRS}")
include_directories("${Boost_INCLUDE_DIRS}")


find_package(FLEX)
find_package(BISON)

bison_target(MyParser parser.yy   ${CMAKE_CURRENT_BINARY_DIR}/parser.cpp COMPILE_FLAGS "--defines=${CMAKE_CURRENT_BINARY_DIR}/parser.h")
flex_target(MyScanner scanner.ll  ${CMAKE_CURRENT_BINARY_DIR}/scanner.cpp)
ADD_FLEX_BISON_DEPENDENCY(MyScanner MyParser)

message(STATUS "scanner outputs: ${FLEX_MyScanner_OUTPUTS}")
message(STATUS "parser outputs: ${BISON_MyParser_OUTPUTS}")
      
include_directories(${CudfParser_SOURCE_DIR})
include_directories(${CudfParser_BINARY_DIR})
include_directories(${CMAKE_CURRENT_BINARY_DIR})
 add_executable(exprtest
	exprtest.cc driver.cc cudf.cc cudfvpkg.cc
  driver.h scanner.h
      ${BISON_MyParser_OUTPUTS}
      ${FLEX_MyScanner_OUTPUTS}
 )
