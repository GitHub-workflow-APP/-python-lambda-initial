from aws_cdk import core
from . import first_service


class PythonLambdaCdkStack(core.Stack):

    def __init__(self, scope: core.Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)
        first_service.FirstService(self, "first svc")

