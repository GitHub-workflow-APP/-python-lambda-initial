# Introduction/Scope

This spec covers initial support -- packaging and entry-point detection -- for AWS Lambda functions written in Python (2.x and 3.x). 

This research does *not* cover the AWS SDK for Python (boto3/botocore).

## Lambda Architecture

Lambda is an AWS hosting service that allows for server-side code (in numerous different languages) to be run.  Unlike traditional application servers or hosting services, the basic unit of Lambda code is a function -- not an entire application.  Each Lambda function has an associated artifact (called a [deployment package](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html)) containing the function and all code necessary to run. A function also has associated configuration data (stored separately in AWS) that indicates, among other things, which actual function/method inside the deployment package's code is the entry point to the Lambda function.  These entry points are called *function handlers*.

Through AWS configuration, Lambda functions can be configured to run under many different situations.  Users can route incoming HTTP requests directly to Lambda functions; functions can be set to run automatically on a periodic basis; they can be triggered in response to other AWS infrastructure events; and more.

Though the core idea behind Lambda functions, from a static-analysis perspective, is not uncommon compared to other server-side frameworks ("there's a runtime environment calling function X as the entry point"), the amount of AWS configuration can be extensive.  To manage this configuration in a more trackable, automated way (and to enable provisioning for automated/manual testing), developers sometimes use packaging/deployment tools that automate much of this work in a somewhat standard, declarative manner (e.g. through config files).  Some of these tools include the [Serverless Framework](https://serverless.com/framework/docs/), [AWS SAM (Serverless Application Model)](https://aws.amazon.com/serverless/sam/), [AWS CDK (Cloud Development Kit)](https://docs.aws.amazon.com/cdk/latest/guide/home.html), and [Apex](https://apex.run/).

There are also higher-level tools designed to abstract away the details of Lambda functions and instead present a more conventional web-framework-like interface.  These may even shim apps written against another web framework, such as [Zappa](https://github.com/Miserlou/Zappa), which lets apps written against Django and Flask to be run on Lambda.  Other examples of this include [Chalice](https://github.com/aws/chalice) and [Apex Up](https://apex.sh/docs/up/).  Support for these is not covered in this document.

Each Lambda function is treated independently by AWS (and has a single entry point), although it is possible (and common) for a single deployment package to contain multiple handler functions.

### Notes on Terminology

* The word ["serverless"](https://en.wikipedia.org/wiki/Serverless_computing) is a general term for an architecture pattern in which an application runs entirely on a hosted provider, in an environment where provisioning and resource management is generally managed by the provider itself (and billing is handled based on usage).  Building an application out of Lambda functions (or analogues like Azure Functions and Google Cloud Functions) is a popular way to build serverless applications. But using Lambda or the term "serverless" does not necessarily mean the capital-S [Serverless Framework](https://serverless.com/framework/docs/) or the AWS [Serverless Application Model (SAM)](https://aws.amazon.com/serverless/sam/) are being used.
* The [Apex](https://apex.run/) tool is completely unrelated to Salesforce's [Apex language](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_intro_what_is_apex.htm).
    * [Apex](https://apex.run/) is somewhat related to [Apex Up](https://apex.sh/docs/up/); they are two entirely separate tools designed for managing Lambda functions written by the same team.


## Packaging and Identifying Handler Functions

From a static-analysis perspective, we can treat Lambda applications like any other framework.  Specifically, we define heuristics for identifying when a given artifact (aka .pya, an archive containing Python code) contains Lambda function handler(s) -- entry points -- and describe taint sources/sinks related to those functions.  Beyond that, everything else is normal Python.

This process may be somewhat more idiosyncratic than other Python server-side frameworks (e.g. Django and Flask), because function handlers do not need to be annotated with a specific value or named in a specific way.  Moreover, due to the number of Lambda management tools that may be in use, there are several different cases to consider.

It is not necessary to model all related AWS configuration (or even to attempt to distinguish between different Lambda functions) to be effective in finding flaws -- identifying functions in uploaded code that are likely to be handler methods (entry points), then treating them as such, will be effective.

### Handler Functions

In Python, handler functions must have exactly two positional ("default") parameters.  They may have additional parameters defined, but any additional parameters must have initial values set.

Virtually all handler functions will look like this (even using the names `event` and `context`, though these may be renamed):

```
def lambda_handler(event, context):
```

But this is also allowed:

```
def different_func(evt, ctx, xyz=123):
```

This function cannot be a function handler (you can configure AWS to set it as a handler, but the runtime will throw an error):

```
def different_func(event):
```

### Identifying Handler Functions in Artifacts

Follow these rules to determine a set of candidate source files.  Once a set has been determined, then every function that has a signature matching the above should be treated as a Lambda entry point.  Note that functions inside Python classes cannot be handler functions.

#### #1.  If a directory called `functions` exists, then every Python file in every subdirectory below `functions` is a candidate source file.  Files in any directories below one level, though, are not.

For example, in the following archive:

```
.
└── functions
    ├── one
    │   ├── misc
    │   │   └── utils.py
    │   └── primero.py
    └── two
        ├── orangefunc.py
        └── utils.py
```

the candidate files are:
* `functions/one/primero.py` 
* `functions/two/orangefunc.py` 
* `functions/two/utils.py` 

This format matches the Apex-mandated layout.

##### Future Work

 For improved accuracy, look for `function.json` files in each subdirectory; parse out the `handler` property to identify the exact function handler (and use their presence to determine candidate source files anywhere in a source tree).  (As of today, though, `.json` files are not included in `.pya` archives.) 


#### #2.  Every python file in the top level directory of the archive is a candidate source file.

This is the more common case; native AWS artifacts are packaged this way. 

For example, in the following archive:

```
.
├── misc
│   └── utils.py
└── primero.py
```

the only candidate file is `primero.py`.


#### Future Work: Dependency Exclusion

Additional Python dependency modules (third-party or not) may be included in a directory that may be named `package` or in subdirectories inside a virtualenv named `site-packages` or `dist-packages`.  If performance on large Lambda deployment packages is an issue, we may need to consider excluding this directory from analysis (or splitting up modules inside, as we do for `node_modules` directories in Node).

See [https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html) for more details.




### Packaging/Upload Guidance

#### General

Create a .zip file containing all Python code and dependencies.   The Python files that contain [handler](https://docs.aws.amazon.com/lambda/latest/dg/python-programming-model-handler-types.html) functions must be in the root of the .zip file.

This is identical to the [Lambda deployment package](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html) that is sent to AWS Lambda to deploy a function.  The same archive submitted to AWS can be uploaded to Veracode.

#### [Serverless Framework](https://serverless.com/framework/docs/)

As part of deployment (the `serverless deploy` command), the Serverless CLI creates a suitable .zip file.  This is stored in the `.serverless` directory at the root of the project.  To regenerate this file, run the `serverless package` command.

The resulting zip file is named for the service name (defined in the `serverless.yml` file). 

Alternatively, zip up the entire source directory of the project, with `serverless.yml` at the root of the zip file.


#### [Apex](https://apex.run)

Combined Project (all functions): Create a .zip file containing the `project.json` file and `functions` directory.  Ensure that these are at the root of the zip file.

Individual functions: From the root of the project directory (the file that contains `project.json`), run `apex build FUNCTION > OUTPUTFILE.zip`, where `FUNCTION` is the name of the function you wish to export.  This will generate a zip file named `OUTPUTFILE.zip`.  Repeat for each function.



#### [AWS Serverless Application Model (SAM)](https://aws.amazon.com/serverless/sam/)

The AWS SAM CLI tool allows developers to declaratively manage Lambda functions and related AWS resources through the use of YAML or JSON configuration files.  

Create a zip file containing all Python code and dependencies that implement Lambda functions.  In a SAM project, the locations of these files will be defined in the `CodeUri` attribute of each Lambda function defined in a project's template configuration (`template.yaml` or `template.json`).

Further documentation is available in the [SAM Specification](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-specification.html) documentation, and specifically in the [AWS::Serverless::Function](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-resource-function.html) reference page.


#### [AWS CDK](https://docs.aws.amazon.com/cdk/latest/guide/home.html)

AWS CDK allows users to programmatically define Lambda functions through the use of the [aws-lambda](https://docs.aws.amazon.com/cdk/api/latest/docs/aws-lambda-readme.html) module.  The source to these can be stored inside the CDK root directory or elsewhere.  Create a zip file with the Python source, as directed above in the "General" section.


#### [Terraform](https://www.terraform.io/docs/)

Like the AWS CDK, Terraform is a powerful tool for configuring infrastructure, including cloud infrastructure and AWS Lambda projects.  The Python source to these functions is often included alongside Terraform configuration (.tf) files.

Create a zip file with the Python source and dependencies for all Lambda functions as described above in the "General" section.  The [`aws_lambda_function`](https://www.terraform.io/docs/providers/aws/r/lambda_function.html) resource entries in Terraform configuration files indicate how the source code for a Lambda function is supplied (e.g. in a local file, S3 bucket, other remote location, etc.)



## DPA

### Sources

```
- Taint.Network
    - The first argument to a handler function (the `event` object).  This is generally an object or dict.

- Taint.Sensitive
    - Note: LambdaContext is the second argument to a handler function.
    - LambdaContext.invoked_function_arn
    - LambdaContext.client_context.env
```

### Sinks

The return value of every handler function is a CWE 80 sink (when the taintedness is Taint.Network) under these circumstances:

- If the return value is a dict that contains the `'statusCode'` property:
    - If the dict also contains a 'headers' property where `'Content-Type'` (case-insensitive) is not a string literal that contains `"application/json"`:
        - The values of the `"body"`, `"headers"`, and `"multiValueHeaders"` keys are CWE 80 sinks
- Else:
    - The entire return value is a CWE 80 sink


## Testcases

This repo contains multiple "ports" of a set of Lambda functions: each designed to mimic a real-world development toolchain/situation.  These are:

* [python-lambda-apex](testcases/python-lambda-apex): The functions managed by Apex
* [python-lambda-cdk](testcases/python-lambda-cdk): The functions managed by AWS CDK
* [python-lambda-sam](testcases/python-lambda-sam): The functions managed by AWS SAM
* [python-lambda-serverless](testcases/python-lambda-serverless): The functions managed by Serverless Framework
* [python-lambda-shellscript](testcases/python-lambda-shellscript): The functions managed by a set of home-grown shell scripts
* [python-lambda-terraform](testcases/python-lambda-terraform): The functions managed by Terraform and the aws provider

Most of the filenames and function names have been changed from repo to repo, but the set of flaws is identical.

### Built Artifacts

This repo also contains a set of built artifacts generated using the instructions above.  These are designed to mimic the exact artifacts that customers will upload.  These are:

* [built-artifacts/aws-deployment-package](built-artifacts/built-artifacts/aws-deployment-package): The most common case: an AWS deployment package (all code in the root)
* [built-artifacts/apex-individual-functions](built-artifacts/built-artifacts/apex-individual-functions): The outputs from `apex build` (multiple zips)
* [built-artifacts/apex-source-archive](built-artifacts/built-artifacts/apex-source-archive): The source tree from an Apex project
* [built-artifacts/serverless-packaged](built-artifacts/built-artifacts/serverless-packaged): The AWS deployment package retrieved from the output of `serverless package`
* [built-artifacts/serverless-source-archive](built-artifacts/built-artifacts/serverless-source-archive): The source tree from a Serverless project
