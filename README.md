# Serverless Testing Workshop

Testing is crucial in any software project. When shifting to a serverless world, we need to accept and embrace multiple paradigm shifts, which also affect how we can test our applications. By doing so on multiple layers, we can drastically increase our confidence of releasing code and having minimal impact on the service availability and stability of the software we develop.

This workshop consists of multiple independent modules which can be done in any order. The modules are

- [Unit Tests](#unit-tests)
- [Local Testing](#local-testing)
- [Integration Tests](#integration-tests)
- [E2E Tests](#e2e-tests)
- [Testing in Production](#testing-in-production)

> For some exercises, you need to have certain tools installed. These will be highlighted at the beginning of the respective exercise.

## Unit Tests

In the Function-as-a-Service (FaaS) realm, unit tests are rather straight forward. The function as the unit under test has a clear interface consisting of inputs (function parameters) and outputs (function return value). We can therefore easily mock any dependencies and assert different outputs for the respective input values.

### Exercise

> Requirements: You need to have [Node.js](https://nodejs.org/) installed.

1. Take a look at the function defined in [unit-tests](./unit-tests) and understand what it does.
1. Investigate and run the unit tests in the directory by first running `npm install` and then `npm test`.
1. Add a unit test that checks correct error handling of the function in case no `jokeID` is provided.

<details>
  <summary>Solution</summary>

```javascript
test("Input errors are handled", async () => {
  const result = await handler({});
  expect(result).toBeDefined();
  expect(result.Error).toBe("no jokeID provided");
});
```

</details>

## Local Testing

Local development for more complex applications can be tedious if we don't have access to the tools we know and love. For web applications, for example, it's useful if we can use [cURL](https://curl.se/) or similar HTTP clients to directly hit our application running locally and verify different scenarios. A nice way to achieve this locally and gain the benefits of being able to develop with our favorite tools is to use wrappers which run our code as a normal web application locally and as a function which understands API Gateway requests when it's running in a serverless context (e.g., AWS Lambda).

In Node.js, [Express](https://expressjs.com/) is a popular framework for building web applications. It can easily be wrapped using another third party library and, as such, function transparently in a Lambda context.

### Exercise

> Requirements: You need to have [Node.js](https://nodejs.org/) installed.

1. Read up on [`serverless-http`](https://github.com/dougmoscrop/serverless-http) and understand how it works
1. Check out the example application in [local-testing](./local-testing) and investigate how it uses the serverless-http framework
1. Run the application locally by running `npm install` and then `npm start`
1. Send an HTTP request to the app (e.g. using `curl localhost:8080`)
1. Deploy the app to AWS Lambda and hook it up with API Gateway.
1. Research how you could do something similar with the web framework and programming language of your choice

## Integration Tests

Integration testing is crucial to being confident that your application behaves as expected towards its peripheral systems and environments. When working with serverless services, this is usually not so easy. Those services are highly abstracted and mostly closed source. That's why we cannot just spin them up on our local computer or in a CI environment. A good alternative is [LocalStack](https://localstack.cloud/) as it provides high-quality emulations for the APIs of many serverless services. By using it, we can run a dummy environment in almost no time, then run tests against it and delete it again. Even though, these tests don't give us a 100% certainty because the emulation may be faulty, they can drastically increase our confidence before deploying to actual infrastructure.

### Exercise

> Requirements: You need to have either [Docker](https://www.docker.com/) (including [docker-compose](https://github.com/docker/compose)) or [Podman](https://podman.io/) (including [podman-compose](https://github.com/containers/podman-compose)) installed.

1. Take a look at the introduction to LocalStack by reading their [overview documentation](https://docs.localstack.cloud/overview/).
1. Investigate the `docker-compose.yml` file in the [`integration-tests`](./integration-tests) directory and understand how it sets up
1. Run `docker compose up -d` or (`PODMAN_COMPOSE_PROVIDER=podman-compose podman compose up -d` for Podman) and visit [localhost:4566/\_localstack/health](http://localhost:4566/_localstack/health) to verify all services are available.
1. Run `aws --endpoint-url http://localhost:4566 dynamodb create-table --table-name jokes --attribute-definitions AttributeName=ID,AttributeType=S --key-schema AttributeName=ID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1` to create the `jokes` table locally.
1. Run `aws --endpoint-url http://localhost:4566 dynamodb list-tables` to verify it has been created.
1. Run `aws --endpoint-url http://localhost:4566 dynamodb put-item --table-name jokes --item '{"ID":{"S":"1"},"Text":{"S":"Hello funny world"}}'` to insert a joke into the newly created table.
1. Run `aws --endpoint-url http://locahlost:4566 dynamodb scan --table-name jokes` to verify it has been inserted.

## E2E Tests

End-to-end tests require a whole environment to be present. The environment should be a similar as possible to the final production environment, the application will run in. Infrastructure as Code allows us to do so by having a clearly declared definition of what an environment looks like. Using that definition, we can spin up ephemeral environments, run our end-to-end tests and then tear them down again. This can usually be done with very low cost, as almost all serverless services are billed on a pay-as-you go model.

As soon as we have our infrastructure defined cleanly as code, we can use a tool like [Terratest](https://terratest.gruntwork.io/) to apply the Terraform code in an automated way using random resource suffixes to prevent name clashes. Terratest then checks certain assertions on the provisioned infrastructure and afterward tears it down again. This can be achieved by using known tools and a mature environment with Go and Terraform as its backbones.

### Exercise

> Requirements: You need to have [Go](https://go.dev/) and either [Terraform](https://www.terraform.io/) or [OpenTofu](https://opentofu.org/) installed.

1. Take a look at the infrastructure code present in [e2e-tests](./e2e-tests) and understand what infrastructure gets provisioned.
1. Investigate the Terratest tests and run them by running `make test`.
1. Add another assertion that sends an HTTP request to our function and checks if it gets a response with the status code `200`. Note that Terratest provides a [`http-helper`](https://pkg.go.dev/github.com/gruntwork-io/terratest/modules/http-helper) package to facilitate that.

<details>
  <summary>Solution</summary>

```go
invokeURL := terraform.Output(t, terraformOptions, "invoke_url")

expectedStatusCode := http.StatusOK
statusCode, _ := httphelper.HttpGet(t, invokeURL+"jokes/1", nil)
if statusCode != http.StatusOK {
    t.Errorf("Expected status code to be %v, got %v", expectedStatusCode, statusCode)
}
```

</details>

## Testing in Production

Many FaaS platforms allow performing canary deployments. By doing so, we don't release a new version of our software to all users at once. Rather, we first release it to a small percentage of them and then gradually increase that percentage. This is a very controlled process that allows us to roll back on failures or increased error rates. We can identify regressions which have slipped through our net of automated testing before they reach too many clients. This can give us a last boost of confidence in order to release and deploy new versions of our software.

### Exercise

1. Get familiar with how AWS CodeDeploy works by reading through their [How it works guide](https://aws.amazon.com/codedeploy/).
1. Investigate the Terraform resources defined in [testing-in-production](./testing-in-production) and understand what they do.
1. Navigate to the function code
1. Install the functions dependencies with `npm install`
1. Navigate to your Terraform module
1. Init and apply the infrastructure code
1. Change something about the function code and apply again to publish a new version (notice the `publish: true` flag in `function.tf`)
1. Visit the [CodeDeploy UI](https://console.aws.amazon.com/codesuite/codedeploy/applications)
1. Choose your application
1. Click "Create deployment" and choose "Use AppSpec editor" with "YAML"
1. Enter the following code into the text field (replacing `RESOURCE_SUFFIX` with the suffix you chose):

   ```yml
   version: 0.0
   Resources:
     - my-function:
         Type: AWS::Lambda::Function
         Properties:
           Name: "canaryRESOURCE_SUFFIX"
           Alias: "production"
           CurrentVersion: "1"
           TargetVersion: "2"
   ```

1. Click "Create deployment"
1. You can now observe in real time how your `production` alias gets switched from version 1 to version 2 gradually using a canary deployment
1. Implement a CodeDeploy deployment for one of the functions you created. You can follow [this tutorial](https://www.ioconnectservices.com/insight/simple-cd-ci-pipeline-for-aws-lambda-walkthrough) if you get stuck.
