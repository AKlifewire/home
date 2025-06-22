import * as cdk from 'aws-cdk-lib';
import * as wafv2 from 'aws-cdk-lib/aws-wafv2';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface SecurityStackProps extends cdk.StackProps {
  envName: string;
}

export class SecurityStack extends cdk.Stack {
  public readonly webAcl: wafv2.CfnWebACL;

  constructor(scope: Construct, id: string, props: SecurityStackProps) {
    super(scope, id, props);

    // WAF Web ACL for DDoS and attack protection
    this.webAcl = new wafv2.CfnWebACL(this, 'SmartHomeWebACL', {
      name: `SmartHome-${props.envName}-WebACL`,
      scope: 'CLOUDFRONT',
      defaultAction: { allow: {} },
      description: 'WAF for Smart Home IoT Platform',
      rules: [
        {
          name: 'RateLimitRule',
          priority: 1,
          statement: {
            rateBasedStatement: {
              limit: 2000,
              aggregateKeyType: 'IP'
            }
          },
          action: { block: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'RateLimitRule'
          }
        },
        {
          name: 'SQLInjectionRule',
          priority: 2,
          statement: {
            sqliMatchStatement: {
              fieldToMatch: { body: {} },
              textTransformations: [
                { priority: 0, type: 'URL_DECODE' },
                { priority: 1, type: 'HTML_ENTITY_DECODE' }
              ]
            }
          },
          action: { block: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'SQLInjectionRule'
          }
        },
        {
          name: 'XSSRule',
          priority: 3,
          statement: {
            xssMatchStatement: {
              fieldToMatch: { body: {} },
              textTransformations: [
                { priority: 0, type: 'URL_DECODE' },
                { priority: 1, type: 'HTML_ENTITY_DECODE' }
              ]
            }
          },
          action: { block: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'XSSRule'
          }
        }
      ],
      visibilityConfig: {
        sampledRequestsEnabled: true,
        cloudWatchMetricsEnabled: true,
        metricName: 'SmartHomeWebACL'
      }
    });

    // Security headers for CloudFront
    const securityHeadersFunction = new cloudfront.Function(this, 'SecurityHeaders', {
      code: cloudfront.FunctionCode.fromInline(`
        function handler(event) {
          var response = event.response;
          var headers = response.headers;
          
          headers['strict-transport-security'] = { value: 'max-age=63072000; includeSubdomains; preload' };
          headers['content-type-options'] = { value: 'nosniff' };
          headers['x-frame-options'] = { value: 'DENY' };
          headers['x-content-type-options'] = { value: 'nosniff' };
          headers['referrer-policy'] = { value: 'strict-origin-when-cross-origin' };
          headers['permissions-policy'] = { value: 'camera=(), microphone=(), geolocation=()' };
          
          return response;
        }
      `)
    });

    // Export WAF ARN for CloudFront association
    new cdk.CfnOutput(this, 'WebACLArn', {
      value: this.webAcl.attrArn,
      exportName: `SmartHome-${props.envName}-WebACL-Arn`
    });
  }
}