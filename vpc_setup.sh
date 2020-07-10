export CIDR=10.0.0.0/24
aws ec2 create-vpc --cidr-block $CIDR > aws_output.txt
cat aws_output.txt
export vpcid=`egrep VpcId aws_output.txt | cut -d":" -f2 | sed 's/"//g' | sed 's/,//g' | cut -d" " -f2`
export CIDRPublic=10.0.0.0/25
export CIDRPrivate=10.0.0.128/25
aws ec2 create-subnet --vpc-id $vpcid --cidr-block $CIDRPublic > aws_output.txt
cat aws_output.txt
export pubsubnetid=`egrep SubnetId aws_output.txt | cut -d":" -f2 | sed 's/"//g' | sed 's/,//g' | cut -d" " -f2`
aws ec2 create-subnet --vpc-id $vpcid --cidr-block $CIDRPrivate > aws_output.txt
cat aws_output.txt
export privsubnetid=`egrep SubnetId aws_output.txt | cut -d":" -f2 | sed 's/"//g' | sed 's/,//g' | cut -d" " -f2`
aws ec2 create-internet-gateway > aws_output.txt
cat aws_output.txt
export IGW=`egrep InternetGatewayId aws_output.txt | cut -d":" -f2 | sed 's/"//g' | sed 's/,//g' | cut -d" " -f2`
aws ec2 attach-internet-gateway --vpc-id $vpcid --internet-gateway-id $IGW
aws ec2 create-route-table --vpc-id $vpcid > aws_output.txt
cat aws_output.txt
export RoutePublic=`egrep RouteTableId aws_output.txt | cut -d":" -f2 | sed 's/"//g' | sed 's/,//g' | cut -d" " -f2`
aws ec2 create-route-table --vpc-id $vpcid > aws_output.txt
cat aws_output.txt
export RoutePrivate=`egrep RouteTableId aws_output.txt | cut -d":" -f2 | sed 's/"//g' | sed 's/,//g' | cut -d" " -f2`
aws ec2 associate-route-table --subnet-id $pubsubnetid --route-table-id $RoutePublic
aws ec2 associate-route-table --subnet-id $privsubnetid --route-table-id $RoutePrivate
aws ec2 modify-subnet-attribute --subnet-id $privsubnetid --map-public-ip-on-launch
aws ec2 create-route --route-table-id $RoutePublic --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW
aws ec2 allocate-address  > aws_output.txt
cat aws_output.txt
export EIP=`egrep AllocationId aws_output.txt | cut -d":" -f2 | sed 's/"//g' | sed 's/,//g' | cut -d" " -f2`
aws ec2 create-nat-gateway --subnet-id $privsubnetid --allocation-id $EIP > aws_output.txt
cat aws_output.txt
export NAT=`egrep NatGatewayId aws_output.txt | cut -d":" -f2 | sed 's/"//g' | sed 's/,//g' | cut -d" " -f2`
while true
do
aws ec2 describe-nat-gateways --nat-gateway-id $NAT > aws_output1.txt
export state=`egrep State aws_output1.txt | cut -d":" -f2 | sed 's/"//g' | sed 's/,//g' | cut -d" " -f2`
if [ "$state" != "pending" ]
then
break
fi
echo "waiting for NAT allocation sleeping for 20s"
sleep 20
done
aws ec2 create-route --route-table-id $RoutePrivate --destination-cidr-block 0.0.0.0/0 --gateway-id $NAT
aws ec2 run-instances --image-id ami-0810abbfb78d37cdf --count 1 --instance-type t2.micro --key-name myec2key --subnet-id $pubsubnetid >aws_output.txt
cat aws_output.txt
aws ec2 run-instances --image-id ami-0810abbfb78d37cdf --count 1 --instance-type t2.micro --key-name myec2key --subnet-id $privsubnetid >aws_output.txt
cat aws_output.txt
