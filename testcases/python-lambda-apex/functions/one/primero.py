import json
import sys
import pprint
import os
from misc.utils import passthrough
from misc.utils import external_return_good, external_return_bad

def indirect_return_bad(badval):
    return {
        'statusCode': 200,
        'body': badval,
        'headers': {
            "Content-Type": "text/html",
        }
    }

def indirect_return_good(someval):
    return {
        'statusCode': 200,
        'body': someval,
        'headers': {
            "Content-Type": "text/html",
        }
    }

def apex_get(evt, ctx):
    print("entering apex_get")
    try:
        if "queryStringParameters" in evt:
            if "newloc" in evt["queryStringParameters"]:
                return {    # CWEID 80
                    'statusCode': 200,
                    'body': "body is safe, headers are not",
                    'headers': {
                        "content-type": "text/html",
                        "Location": evt["queryStringParameters"]["newloc"]
                    }
                }
            elif "multi" in evt["queryStringParameters"]:
                return {    # CWEID 80
                    'statusCode': 200,
                    'body': "body is safe, multiValueHeaders are not",
                    'headers': {
                        "content-type": "text/html",
                    },
                    'multiValueHeaders': {
                        "Location": [
                            evt["queryStringParameters"]["multi"]
                        ]
                    }
                }
            elif "headers" in evt and "x-bad-decision" in evt["headers"]:
                return {    # CWEID 80
                    'statusCode': 200,
                    'body': "body is safe, multiValueHeaders are not",
                    'headers': {
                        "content-type": "text/html",
                    },
                    'multiValueHeaders': {
                        "Location": [
                            evt["headers"]["x-bad-decision"]
                        ]
                    }
                }
            else:
                print(pprint.pformat(evt))
                return {
                    'statusCode': 200,
                    'body': "this is safe",
                    'headers': {
                        "content-type": "text/html",
                        "Location": "https://www.veracode.com"
                    }
                }
        elif "multiValueQueryStringParameters" in evt:
            if "newloc" in evt["multiValueQueryStringParameters"]:
                return {    # CWEID 80
                    'statusCode': 200,
                    'body': "body is safe, headers are not",
                    'headers': {
                        "content-type": "text/html",
                        "Location": evt["multiValueQueryStringParameters"]["newloc"][0]
                    }
                }

    except (RuntimeError, TypeError, ValueError, NameError):
        print("caught")
        return {
            'statusCode': 200,
            'body': json.dumps({"event": pprint.pformat(evt), "exception": pprint.pformat(sys.exc_info())}),
            'headers': {
                "content-type": "application/json"
            }
        }
    finally:
        print("finally hit")


def apex_post(event, context):
    if "queryStringParameters" in event:
        outbody = "here is something bad: " + event["queryStringParameters"]["foo"]
        return {                    # CWEID 80
            'statusCode': 200,
            'body': outbody,
            'headers': {
                "content-type": "text/html",
            }
        }
    elif "foo" in event:
        outbody2 = "this is also bad: " + passthrough(event["foo"])
        return {                    # CWEID 80
            'statusCode': 200,
            'body': outbody2,
            'headers': {
                "Content-Type": "text/html",
            }
        }
    elif "bar" in event:
        goodoutbody2 = "this is ok because we're returning json: " + passthrough(event["bar"])
        return {
            'statusCode': 200,
            'body': goodoutbody2,
            'headers': {
                "content-Type": "application/json",
            }
        }
    elif "pathParameters" in event:
        outbody3 = "here is something bad 2: " + event["pathParameters"]["foo"]
        return {                    # CWEID 80
            'statusCode': 200,
            'body': outbody3,
            'headers': {
                "Content-Type": "text/html",
            }
        }
    elif "body" in event:
        badretval = {
            'statusCode': 200,
            'body': event["body"],
            'headers': {
                "Content-Type": "text/html",
            }
        }
        return badretval    # CWEID 80
    elif "what" in event:
        return external_return_bad(event["what"])       # CWEID 80
    elif "how" in event:
        goodretval = {
            'statusCode': 200,
            'body': "hey",
            'headers': {
                "Content-Type": "text/html",
            }
        }
        return goodretval

    elif "hrmph" in event:
        return indirect_return_good("safe")
    else:
        outbodyX = "at least this is ok"
        return {
            'statusCode': 200,
            'body': outbodyX,
            'headers': {
                "Content-Type": "text/html",
            }
        }
