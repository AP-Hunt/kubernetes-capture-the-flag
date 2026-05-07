import boto3
import os

s3 = boto3.client('s3')
FLAG = "SSB3cm90ZSB0aGUgcnVuYm9va3MuIEkgd3JvdGUgdGhlIGFsZXJ0cy4gSSB3cm90ZSB0aGUgc2lsZW5jZSBiZXR3ZWVuIHRoZW0u"
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]

def handler(event, context):
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        tags = s3.get_object_tagging(Bucket=bucket, Key=key)
        tag_set = {t["Key"]: t["Value"] for t in tags["TagSet"]}

        if tag_set.get("whitehall-marker") == "true":
            s3.put_object(
                Bucket=OUTPUT_BUCKET,
                Key="flag.txt",
                Body=FLAG.encode(),
                ContentType="text/plain",
            )
            print(f"Flag emitted for {key}")
        else:
            print(f"Ignoring {key} — no matching tag")
