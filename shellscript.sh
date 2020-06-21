ls -1 | grep vmserver > adinfo_check_status_temp.csv
while read file
do
cat $file | awk '{
    print $1, $2, $3, $4;}' >> adinfo_check_status_$1_$2.csv
rm $file
done < adinfo_check_status_temp.csv
cat ./adinfo_check_status_$1_$2.csv
awk -F ' ' 'BEGIN{ OFS=";"; print "sep=;\nResource Group Name;VM Name;Hostname;Zone;"};
{print $1, $2, $3, $4;}' ./adinfo_check_status_$1_$2.csv >> ./adinfo_check_status.csv 
