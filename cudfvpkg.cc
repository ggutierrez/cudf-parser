#include <sstream>

#include "cudf.h"

using namespace std;

Vpkg::Vpkg(void)
  : rop(ROP_NOP) {}

Vpkg::Vpkg(const Vpkg& v) 
  : name(v.name), rop(v.rop), version(v.version) {}

Vpkg::Vpkg(const std::string& nm, RelOp r, unsigned int v)
  : name(nm), rop(r), version(v) {}

const std::string& Vpkg::getName(void) const {
  return name;
}

RelOp Vpkg::getRel(void) const {
  return rop;
}

unsigned int Vpkg::getVersion(void) const {
  return version;
}

bool Vpkg::versioned(void) const {
  return rop != ROP_NOP;
}

std::string Vpkg::serialize(void) const {
  ostringstream ss;
  ss << *this;
  return ss.str();
}

ostream& operator<< (ostream& o, RelOp ro) {
  switch(ro) {
    case ROP_EQ:  o << "="; break;
    case ROP_NEQ: o << "!="; break;
    case ROP_GE: o << ">="; break;
    case ROP_GT:  o << ">"; break;
    case ROP_LE: o << "<="; break;
    case ROP_LT:  o << "<"; break;
    case ROP_NOP: o << "-nop-"; break;
  }
  return o;
}

ostream& operator<< (ostream& o, Keep k) {
  switch(k) {
    case KP_NONE: o << "None"; break;
    case KP_VERSION: o << "Version"; break;
    case KP_PACKAGE: o << "Package"; break;
    case KP_FEATURE: o << "Feature"; break;
  }
  return o;
}


ostream& operator<< (ostream& o, const Vpkg& vp) {
  o << "<" << vp.name;
  if (vp.rop == ROP_NOP) {
    o << ",*>";
    return o;
  }
  o << vp.rop << vp.version << ">";
  return o;
}
