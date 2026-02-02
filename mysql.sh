#!/bin/bash
source ./common.sh

check_root

dnf list installed mysql-server &>>$LOGS_FILE
if [ $? -eq 0 ]; then
    echo -e "MySQL Server already installed ... $Y SKIPPING $N"
else    
    dnf install mysql-server -y &>>$LOGS_FILE
    VALIDATE $? "Installing MySQL Server"
fi

systemctl enable mysqld &>>$LOGS_FILE
VALIDATE $? "Enabling MySQL Service"

systemctl start mysqld &>>$LOGS_FILE
VALIDATE $? "Starting MySQL Service"

#Below code will be useful for idempotent nature
mysql -h $DOMAIN_NAME -uroot -p${mysql_root_password} -e 'show databases;' &>>$LOGS_FILE
if [ $? -ne 0 ]
then
    mysql_secure_installation --set-root-pass ${mysql_root_password} &>>$LOGS_FILE
    VALIDATE $? "Setting MySQL Root Password"
else
    echo -e "MySQL Root password is already setup...$Y SKIPPING $N"
fi