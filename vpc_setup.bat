SET CIDR=10.0.0.0/24
aws ec2 create-vpc --cidr-block %CIDR% > aws_output.txt
for /f  "delims=" %%i in ('findstr /L  /C:VpcId aws_output.txt') do set vpcid=%%i
set vpcid=%vpcid:*: "=%
set vpcid=%vpcid:~0,-2%
SET CIDRPublic=10.0.0.0/25
SET CIDRPrivate=10.0.0.128/25
aws ec2 create-subnet --vpc-id %vpcid% --cidr-block %CIDRPublic% > aws_output.txt
for /f  "delims=" %%i in ('findstr /L  /C:SubnetId aws_output.txt') do set pubsubnetid=%%i
set pubsubnetid=%pubsubnetid:*: "=%
set pubsubnetid=%pubsubnetid:~0,-2%
aws ec2 create-subnet --vpc-id %vpcid% --cidr-block %CIDRPrivate% > aws_output.txt
for /f  "delims=" %%i in ('findstr /L  /C:SubnetId aws_output.txt') do set privsubnetid=%%i
set privsubnetid=%privsubnetid:*: "=%
set privsubnetid=%privsubnetid:~0,-2%
aws ec2 create-internet-gateway > aws_output.txt
for /f  "delims=" %%i in ('findstr /L  /C:InternetGatewayId aws_output.txt') do set IGW=%%i
set IGW=%IGW:*: "=%
set IGW=%IGW:~0,-2%
aws ec2 attach-internet-gateway --vpc-id %vpcid% --internet-gateway-id %IGW%
aws ec2 create-route-table --vpc-id %vpcid% > aws_output.txt
for /f  "delims=" %%i in ('findstr /L  /C:RouteTableId aws_output.txt') do set RoutePublic=%%i
set RoutePublic=%RoutePublic:*: "=%
set RoutePublic=%RoutePublic:~0,-2%
aws ec2 create-route-table --vpc-id %vpcid% > aws_output.txt
for /f  "delims=" %%i in ('findstr /L  /C:RouteTableId aws_output.txt') do set RoutePrivate=%%i
set RoutePrivate=%RoutePrivate:*: "=%
set RoutePrivate=%RoutePrivate:~0,-2%
aws ec2 associate-route-table  --subnet-id %pubsubnetid% --route-table-id %RoutePublic% 
aws ec2 associate-route-table  --subnet-id %privsubnetid% --route-table-id %RoutePrivate% 
aws ec2 modify-subnet-attribute --subnet-id %privsubnetid% --map-public-ip-on-launch
aws ec2 create-route --route-table-id %RoutePublic% --destination-cidr-block 0.0.0.0/0 --gateway-id %IGW%
aws ec2 allocate-address  > aws_output.txt
for /f  "delims=" %%i in ('findstr /L  /C:AllocationId aws_output.txt') do set EIP=%%i
set EIP=%EIP:*: "=%
set EIP=%EIP:~0,-2%
aws ec2 create-nat-gateway --subnet-id %privsubnetid% --allocation-id %EIP% > aws_output.txt
for /f  "delims=" %%i in ('findstr /L  /C:NatGatewayId aws_output.txt') do set NAT=%%i
set NAT=%NAT:*: "=%
set NAT=%NAT:~0,-2%
:NATCHECK
echo Waiting for the availability of NAT Gateway...
TIMEOUT 30
aws ec2 describe-nat-gateways > aws_output1.txt
for /f  "delims=" %%i in ('findstr /L  /C:State aws_output1.txt') do set state=%%i
set state=%state:*: "=%
set state=%state:~0,-2%
if "%state%"=="pending" GOTO NATCHECK
aws ec2 create-route --route-table-id %RoutePrivate% --destination-cidr-block 0.0.0.0/0 --gateway-id %NAT%
aws ec2 run-instances --image-id ami-0810abbfb78d37cdf --count 1 --instance-type t2.micro --key-name myec2key --subnet-id %pubsubnetid%
aws ec2 run-instances --image-id ami-0810abbfb78d37cdf --count 1 --instance-type t2.micro --key-name myec2key --subnet-id %privsubnetid%
