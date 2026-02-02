source ./common.sh

check_root

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

mysql -h $MYSQL_HOST -uroot -p${mysql_root_password} -e 'use transactions' &>>$LOGS_FILE
if [ $? -eq 0 ]; then
    echo -e "Backend schema already Loaded ... $Y SKIPPING $N"
else
    mysql -h $MYSQL_HOST -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGS_FILE
    VALIDATE $? "Loading backend schema"
fi

systemctl restart backend &>>$LOGS_FILE
VALIDATE $? "Restarting backend Service"