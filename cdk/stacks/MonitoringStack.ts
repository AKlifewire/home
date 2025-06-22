import * as cdk from 'aws-cdk-lib';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import { Construct } from 'constructs';

export interface MonitoringStackProps extends cdk.StackProps {
  envName: string;
  alertEmail?: string;
}

export class MonitoringStack extends cdk.Stack {
  public readonly dashboard: cloudwatch.Dashboard;
  public readonly alertTopic: sns.Topic;

  constructor(scope: Construct, id: string, props: MonitoringStackProps) {
    super(scope, id, props);

    this.alertTopic = new sns.Topic(this, 'SmartHomeAlerts', {
      topicName: `SmartHome-${props.envName}-Alerts`
    });

    if (props.alertEmail) {
      this.alertTopic.addSubscription(new subscriptions.EmailSubscription(props.alertEmail));
    }

    const deviceOnlineMetric = new cloudwatch.Metric({
      namespace: 'SmartHome/Devices',
      metricName: 'DevicesOnline'
    });

    const apiErrorsMetric = new cloudwatch.Metric({
      namespace: 'AWS/ApiGateway',
      metricName: '4XXError'
    });

    this.dashboard = new cloudwatch.Dashboard(this, 'SmartHomeDashboard', {
      dashboardName: `SmartHome-${props.envName}-Dashboard`,
      widgets: [
        [new cloudwatch.GraphWidget({
          title: 'Device Status',
          left: [deviceOnlineMetric],
          width: 12
        })]
      ]
    });

    new cloudwatch.Alarm(this, 'HighErrorRate', {
      metric: apiErrorsMetric,
      threshold: 10,
      evaluationPeriods: 2
    }).addAlarmAction(new cloudwatch.SnsAction(this.alertTopic));
  }
}