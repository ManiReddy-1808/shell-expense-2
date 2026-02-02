#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR=$PWD  # or $(pwd)
MYSQL_HOST=mysql.dawsmani.site
PASSWORD=ExpenseApp@1

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USER_ID -gt 0 ]; then
    echo -e " $R Please run this script with root user :) $N" | tee -a $LOGS_FILE
    exit 3;
fi

mkdir -p $LOGS_FOLDER

# tee command is used to write the output to log file as well as to the console
VALIDATE(){  
    if [ $1 -eq 0 ]; then
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    else 
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
    fi
}

dnf list installed nodejs &>>$LOGS_FILE
if [ $? -eq 0 ]; then
    echo -e "NodeJS already installed ... $Y SKIPPING $N"
else
    dnf module disable nodejs -y &>>$LOGS_FILE
    VALIDATE $? "Disabling NodeJS Module"

    dnf module enable nodejs:20 -y &>>$LOGS_FILE
    VALIDATE $? "Enabling NodeJS 20 Module"

    dnf install nodejs -y &>>$LOGS_FILE
    VALIDATE $? "Installing NodeJS"
fi

id expense &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "expense system user" expense &>>$LOGS_FILE
    VALIDATE $? "Expense User Created"
else
    echo -e "expense user already exists ...$Y SKIPPING $N"
fi

mkdir -p /app 

curl -o /tmp/backend.zip https://expense-joindevops.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGS_FILE
VALIDATE $? "Downloading Backend App"

cd /app 
VALIDATE $? "Changing Directory to /app"

rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing Old App Content"

unzip /tmp/backend.zip &>>$LOGS_FILE
VALIDATE $? "Extracting Backend App Code"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS Dependencies"

#BCurrently we are in app directory, so moving to script dir
cp $SCRIPT_DIR/backend.service /etc/systemd/system/backend.service
VALIDATE $? "Copying Backend SystemD Service File"

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Reloading SystemD"

systemctl enable backend &>>$LOGS_FILE
VALIDATE $? "Enabling backend Service"

systemctl start backend &>>$LOGS_FILE
VALIDATE $? "Starting backend Service"


dnf list installed mysql &>>$LOGS_FILE
if [ $? -eq 0 ]; then
    echo -e "MySQL Client already installed ... $Y SKIPPING $N"
else
    dnf install mysql -y &>>$LOGS_FILE
    VALIDATE $? "Installing mysql"
fi

mysql -h $MYSQL_HOST -uroot -p${PASSWORD} -e 'use transactions' &>>$LOGS_FILE
if [ $? -eq 0 ]; then
    echo -e "Backend schema already Loaded ... $Y SKIPPING $N"
else
    mysql -h $MYSQL_HOST -uroot -p${PASSWORD} < /app/schema/backend.sql &>>$LOGS_FILE
    VALIDATE $? "Loading backend schema"
fi

systemctl restart backend &>>$LOGS_FILE
VALIDATE $? "Restarting backend Service"