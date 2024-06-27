#!/usr/bin/env python3

from aws_cdk import core

from python_lambda_cdk.python_lambda_cdk_stack import PythonLambdaCdkStack


app = core.App()
PythonLambdaCdkStack(app, "python-lambda-cdk")

app.synth()
