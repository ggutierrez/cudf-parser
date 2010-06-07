
#include <boost/typeof/typeof.hpp>
#include <boost/foreach.hpp>

#include "cudf.h"

using namespace std;

/*
 * CudfDoc
 */
CudfDoc::CudfDoc(void) {}

/*
 * CudfPackage
 */
CudfPackage::CudfPackage(void) {}

void CudfPackage::name(const std::string& nm) {
  pk_info.get<5>() = nm; 
}

const std::string& CudfPackage::name(void) const {
  return pk_info.get<5>(); 
}


void CudfPackage::version(unsigned int v) {
  pk_info.get<6>() = v; 
}


ostream& operator<< (ostream& o, const CudfPackage& p) {
  o << "Package: " << p.name() << endl;
    //    << "Version: " << p.version() << endl
    //  << "Installed: " << (p.installed() ? "true" : "false") << endl;
}

void printList(ostream& o, const vpkglist_t& vpl, const char *sep ) {
  BOOST_AUTO(i, vpl.begin());
  for (BOOST_AUTO(next,i); i != vpl.end(); i=next) {
    ++next;
    o << *i;
    if (next != vpl.end())
      o << sep;
  }
}

ostream& operator<< (ostream& o, const vpkglist_t& l) {
  printList(o,l,",");
  return o;
}

ostream& operator<< (ostream& o, const list_vpkglist_t& ll) {
  BOOST_AUTO(it, ll.begin());
  for (BOOST_AUTO(next, it); it != ll.end(); it=next) {
    ++next;
    printList(o,*it,"|");
    if(next != ll.end())
      o << ",";
  }
  return o;
}
