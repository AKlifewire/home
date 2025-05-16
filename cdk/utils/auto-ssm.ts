import * as ssm from 'aws-cdk-lib/aws-ssm';
import { Construct } from 'constructs';

export function createLambdaSsmParameter(
  scope: Construct,
  app: string,
  envName: string,
  name: string,
  value: string
) {
  return new ssm.StringParameter(scope, `${name}FunctionParam`, {
    parameterName: `${app}-${envName}-lambda-${name}`, // No slashes, unique per env
    stringValue: value,
  });
}