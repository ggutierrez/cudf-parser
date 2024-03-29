#ifndef __CUDF_H_
#define __CUDF_H_

#include <boost/tuple/tuple.hpp>
#include <string>
#include <vector>

namespace example {
  /* Forward declaration of the driver class because some of the data structures
   here are filled by the parser and friend membership is defined*/
  class Driver;
}

/**
 * \brief Relational operators definition
 */
enum RelOp {
  ROP_EQ,   /// equality
  ROP_NEQ,	/// disequality
  ROP_GT, 	/// greater than
  ROP_GE,	  /// greater or equal
  ROP_LT, 	/// less than
  ROP_LE, 	/// less or equal
  ROP_NOP,  /// no operation
};
/// Output of relational operators
std::ostream& operator<< (std::ostream& os, RelOp op);
/**
 * \brief Relational operators definition
 */
enum Keep {
  KP_PACKAGE,
  KP_VERSION,
  KP_FEATURE,
  KP_NONE
};
/// Output for keep property
std::ostream& operator<< (std::ostream& os, Keep kp);
/**
 * \brief Package constraint information.
 *
 * This parser does not make any difference between equality or any other
 * kind of constraints.
 */
class Vpkg {
public:
  /// Name of the package in the statement
  std::string name;
  /// Relational operator
  RelOp rop;
  /// Version
  unsigned int version;
  /// Default constructor
  Vpkg(void);
  /// Copy constructor
  Vpkg(const Vpkg& v);
  /// Constructor for artificial vpkg-s
  Vpkg(const std::string& nm, RelOp r, unsigned int v);
  /// Returns the name
  const std::string& getName(void) const;
  /// Returns the relation
  RelOp getRel(void) const;
  /// Returns the version
  unsigned int getVersion(void) const;
  /// Tests whether is a versioned statement or not
  bool versioned(void) const;
  /// Returns a serialization of the constraint
  std::string serialize(void) const;
};
/// Output of constraint information.
std::ostream& operator<< (std::ostream& os, const Vpkg& c);
/// List of package constraints
typedef std::vector<Vpkg> vpkglist_t;
/// Output of list of package constraints
std::ostream& operator<< (std::ostream& os, const vpkglist_t& l);
/// List of lists of package constraints
typedef std::vector<vpkglist_t> list_vpkglist_t;
/// Output of list of lists of package constraints
std::ostream& operator<< (std::ostream& os, const list_vpkglist_t& ll);
/**
 * \brief Package in the universe of a cudf spec.
 */
class CudfPackage {
public:
  /**
   * \brief The main data structure to keep information about a package.
   *
   * 0 : keep property
   * 1 : installed
   * 2 : conflicts
   * 3 : provides
   * 4 : dependencies
   * 5 : name
   * 6 : version
   */
  typedef 
  boost::tuple<Keep,bool,vpkglist_t,vpkglist_t,list_vpkglist_t,
               std::string,unsigned int>
  pkg_info_t;
  pkg_info_t pk_info;
  /// Default constructor
  CudfPackage(void);
public:
  /// \name Read only interface
  //@{
  /// Returns the keep property
  Keep keep(void) const;
  /// Returns the install property
  bool installed(void) const;
  /// Returns the provides
  const vpkglist_t& provides(void) const;
  /// Returns the conflicts
  const vpkglist_t& conflicts(void) const;
  /// Returns the dependencies
  const list_vpkglist_t& depends(void) const;
  /// Returns the name of the package
  const std::string& name(void) const;
  /// Returns the version
  unsigned int version(void) const;
  //@}
	/// Sets the package as installed
	void install(bool st);
};
/// Output \a pkg to \a os
std::ostream& operator << (std::ostream& os, const CudfPackage& pkg);
/**
 * \brief Cudf document representation
 *
 * This class abstracts the concept of a cudf document. It contains
 * a universe (set of packages) and a request.
 */
class CudfDoc {
  friend class example::Driver;
public:
  /**
   * \brief Request information.
   *
   * 0 : constraints to install
   * 1 : constraints to upgrade
   * 2 : constraints to remove
   */
  typedef
    boost::tuple<vpkglist_t,vpkglist_t,vpkglist_t>
    request_t;
  /// Datastructure for the universe of packages
  typedef
    std::vector<CudfPackage> packages_t;
private:
  /// Storage for the universe
  packages_t universe;
  /// Storage for the request
  request_t request;
  /// Indicates if the document has a request section or not
  bool hasRequest_;
  /// Parse the cudf document contained in \a in.
  void parse(std::istream& in);
public:
  /// \name Parser interface
  //@{
  /// Default constructor
  CudfDoc(void);
  /// Add a package to the universe
  void addPackage(const CudfPackage& pkg);
  /// Add the constraints in \a i to the install part of the request
  void addInstall(const vpkglist_t& i);
  /// Add the constraints in \a i to the iupgrade part of the request
  void addUpgrade(const vpkglist_t& u);
  /// Add the constraints in \a i to the remove part of the request
  void addRemove(const vpkglist_t& r);
  //@}
  /// Number of packages in the document
  unsigned int packages(void) const;
  /// Tests whether the document contains a request
  bool hasRequest(void) const;
  /// Return the packages
  const std::vector<CudfPackage>& getPackages(void) const;
  //TODO: this is needed by the updater but now that the parser is in c we should change this.
  std::vector<CudfPackage>::iterator
  pkg_mbegin(void) { return universe.begin(); }
  std::vector<CudfPackage>::iterator
  pkg_mend(void) { return universe.end(); }
  /// Return the install request
  const vpkglist_t& reqToInstall(void) const;
  /// Return the upgrade request
  const vpkglist_t& reqToUpgrade(void) const;
  /// Return the remove request
  const vpkglist_t& reqToRemove(void) const;
};   
/// Output a Cudf document \a doc on stream \a os
std::ostream& operator << (std::ostream& os, const CudfDoc& doc);
/// Function to parse a stream containing a cudf specification and create a document
bool parse(std::istream& is, CudfDoc& doc);
#endif
