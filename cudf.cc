
#include <boost/typeof/typeof.hpp>
#include <boost/foreach.hpp>

#include "cudf.h"

#define  foreach BOOST_FOREACH
using namespace std;

/*
 * CudfDoc
 */
CudfDoc::CudfDoc(void) {}

void CudfDoc::addPackage(const CudfPackage& pkg) {
  universe.push_back(pkg);
}

unsigned int CudfDoc::packages(void) const {
  return universe.size();
}

ostream& operator << (ostream& o, const CudfDoc& d) {
  foreach (const CudfPackage& pi, d.getPackages()) {
    o << "package: " << pi.name() << endl;
    o << "version: " << pi.version() << endl;
    o << "installed: " << (pi.installed() ? "true" : "false") << endl;
    o << endl;
  }
  return o;
}

/*
 * CudfPackage
 */
CudfPackage::CudfPackage(void) {}

const std::string& CudfPackage::name(void) const {
  return pk_info.get<5>(); 
}

unsigned int CudfPackage::version(void) const {
  return pk_info.get<6>(); 
}

bool CudfPackage::installed(void) const {
  return pk_info.get<1>(); 
}

Keep CudfPackage::keep(void) const {
  return pk_info.get<0>(); 
}

const vpkglist_t& CudfPackage::provides(void) const {
  return pk_info.get<3>(); 
}

const vpkglist_t& CudfPackage::conflicts(void) const {
  return pk_info.get<2>(); 
}

const list_vpkglist_t& CudfPackage::depends(void) const {
  return pk_info.get<4>(); 
}

ostream& operator<< (ostream& o, const CudfPackage& p) {
  o << "Package: " << p.name() << endl;
  //    << "Version: " << p.version() << endl
  //  << "Installed: " << (p.installed() ? "true" : "false") << endl;
	return o;
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
