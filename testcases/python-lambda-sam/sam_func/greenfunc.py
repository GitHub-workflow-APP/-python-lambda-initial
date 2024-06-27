import json
import os
import pprint

from utils import passthrough
from utils import external_return_good, external_return_bad

def gfunc(e, c):
    print("hello gfunc")
    print("event: " + pprint.pformat(e))
    try:
        if "invals" in e:
            if "foo" in e["invals"]:
                badout1 = e["invals"]["foo"][0]
                return {        # CWEID 80
                    "innocuous": badout1
                }
            elif "bar" in e["invals"]: 
                badout2 = e["invals"]["bar"][0]
                return {
                    "statusCode": 200,
                    "innocuous": badout2
                }
            elif "baz" in e["invals"]: 
                badout3 = e["invals"]["baz"][0]
                return {            # CWEID 80
                    "result": badout3
                }
        return {
            "result": "<b>error</b>"
        }
    except (RuntimeError, TypeError, ValueError, NameError):
        print("caught")
        return {
            'result': 'error',
            'eventinfo': json.dumps(pprint.pformat(e)),
        }
    finally:
        print("finally hit")


