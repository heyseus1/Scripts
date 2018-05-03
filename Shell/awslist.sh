aws ec2 describe-instances --output text --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,PrivateIpAddress]' | sort -k 2 | column -t
