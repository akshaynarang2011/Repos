l=`wc -l /data/employee.csv | cut -d' ' -f1` 
l=`expr $l - 1` 
echo "empno,name,total" > /data/employee_process.csv 
for i in `cat /landing/employee.csv | tail -$l`
do 
        no=`echo $i | cut -d"," -f1`
        name=`echo $i | cut -d"," -f2`
        x1=`echo $i | cut -d"," -f3`
        x2=`echo $i | cut -d"," -f4`
        x3=`echo $i | cut -d"," -f5`
        x3=`echo $x3 | sed 's/\r$//'`
        total=`expr $x1 + $x2 + $x3`
        echo $no","$name","$total >> /data/employee_process.csv 
done
