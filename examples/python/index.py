#
# Copyright 2005-2012 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
#
# In applying this licence, ECMWF does not waive the privileges and immunities granted to it by
# virtue of its status as an intergovernmental organisation nor does it submit to any jurisdiction.
#

import traceback
import sys,os

from eccode import *

INPUT='../../data/index.grib'
VERBOSE=1 # verbose error reporting

def product(*args, **kwds):
    # product('ABCD', 'xy') --> Ax Ay Bx By Cx Cy Dx Dy
    # product(range(2), repeat=3) --> 000 001 010 011 100 101 110 111
    pools = map(tuple, args) * kwds.get('repeat', 1)
    result = [[]]
    for pool in pools:
        result = [x+[y] for x in result for y in pool]
    for prod in result:
        yield tuple(prod)

def example():
    index_keys = ["shortName","level","number","step"]
    index_file = "my.idx"

    iid = None

    if (os.path.exists(index_file)):
        iid = index_read(index_file)
    else:
        iid = index_new_from_file(INPUT,index_keys)

        # multiple files can be added to an index:
        # index_add_file(iid,"grib file to add")

        index_write(iid,index_file)

    index_vals = []

    for key in index_keys:
        print "%sSize=%d" % (
            key,
            index_get_size(iid,key)
        )

        key_vals = index_get(iid,key)
        print " ".join(key_vals)

        index_vals.append(key_vals)

    for prod in product(*index_vals):
        for i in range(len(index_keys)):
            index_select(iid,index_keys[i],prod[i])

        while 1:
            gid = new_from_index(iid)
            if gid is None: break
            print " ".join(["%s=%s" % (key,get(gid,key)) for key in index_keys])
            release(gid)

    index_release(iid)
    

def main():
    try:
        example()
    except InternalError,err:
        if VERBOSE:
            traceback.print_exc(file=sys.stderr)
        else:
            print >>sys.stderr,err.msg

        return 1

if __name__ == "__main__":
    sys.exit(main())
