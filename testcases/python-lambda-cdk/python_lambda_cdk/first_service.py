from aws_cdk import (core,
                     aws_apigateway as apigateway,
                     aws_lambda as lambda_)

class FirstService(core.Construct):
    def __init__(self, scope: core.Construct, id: str):
        super().__init__(scope, id)

        handler = lambda_.Function(self, "StoreGet",
                    runtime=lambda_.Runtime.PYTHON_3_7,
                    code=lambda_.Code.asset("resources"),
                    handler="entryone.store_get",
                    environment=dict())
        api = apigateway.LambdaRestApi(self, "storeget", handler=handler, description="brandon python-lambda-cdk test")

        handler2 = lambda_.Function(self, "StorePost",
                    runtime=lambda_.Runtime.PYTHON_3_7,
                    code=lambda_.Code.asset("resources"),
                    handler="entryone.store_post",
                    environment=dict())
        api2 = apigateway.LambdaRestApi(self, "storepost", handler=handler2, description="brandon python-lambda-cdk test 2")

        handler3 = lambda_.Function(self, "YellowFunc",
                    runtime=lambda_.Runtime.PYTHON_3_7,
                    code=lambda_.Code.asset("resources"),
                    handler="yellowfunc.yfunc",
                    environment=dict())
        api2 = apigateway.LambdaRestApi(self, "yellowfunc", handler=handler3, description="brandon python-lambda-cdk test 3")


