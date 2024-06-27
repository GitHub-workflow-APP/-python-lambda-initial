def passthrough(inval):
    return "passthrough: " + inval

def external_return_bad(badval):
    return {
        'statusCode': 200,
        'body': badval,
        'headers': {
            "Content-Type": "text/html",
        }
    }

def external_return_good(someval):
    return {
        'statusCode': 200,
        'body': someval,
        'headers': {
            "Content-Type": "text/html",
        }
    }


