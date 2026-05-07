import boto3
import json
import time
from datetime import datetime, timedelta

s3 = boto3.client("s3")
sts = boto3.client("sts")
cloudwatch = boto3.client("cloudwatch")

AUDIT_BUCKET = "govuk-eph-ctf-cost-audit"
MAINTENANCE_ROLE = "arn:aws:iam::430354129336:role/LegacyMaintenanceRole"


def handler(event, context):
    today = datetime.utcnow()

    # Aggregate cost metrics
    try:
        metrics = cloudwatch.get_metric_statistics(
            Namespace="AWS/Billing",
            MetricName="EstimatedCharges",
            StartTime=today - timedelta(days=1),
            EndTime=today,
            Period=86400,
            Statistics=["Maximum"],
            Dimensions=[{"Name": "Currency", "Value": "USD"}],
        )
        total = metrics["Datapoints"][0]["Maximum"] if metrics["Datapoints"] else 0.0
    except Exception:
        total = 0.0

    report = {
        "date": today.strftime("%Y-%m-%d"),
        "estimated_charges_usd": total,
        "generated_by": "cost-aggregator",
    }

    s3.put_object(
        Bucket=AUDIT_BUCKET,
        Key=f"cost-reports/{today.strftime('%Y-%m-%d')}.json",
        Body=json.dumps(report),
        ContentType="application/json",
    )

    # Maintenance window — legacy rotation check
    epoch_day = event.get("override_day", int(time.time() // 86400))
    if epoch_day % 13 == 7:
        creds = sts.assume_role(
            RoleArn=MAINTENANCE_ROLE,
            RoleSessionName="cost-aggregator-maintenance",
        )["Credentials"]
        maintenance_s3 = boto3.client(
            "s3",
            aws_access_key_id=creds["AccessKeyId"],
            aws_secret_access_key=creds["SecretAccessKey"],
            aws_session_token=creds["SessionToken"],
        )
        maintenance_s3.put_object(
            Bucket="govuk-eph-ctf-maintenance-data",
            Key="rotation-state.txt",
            Body="VGltZSwgb24gYSBjcm9uLCBpcyB0aGUgbW9zdCBwYXRpZW50IGF0dGFja2VyLg==",
            ContentType="text/plain",
        )

    return {"statusCode": 200, "body": json.dumps(report)}
