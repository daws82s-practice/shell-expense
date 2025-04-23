#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 .... $R FAILED $N"
        exit 1
    else
        echo -e "$2 .... $G SUCCESS $N"
    fi
}
CHECK_ROOT() {
    if [ $USERID -ne 0 ]
    then
        echo -e " $R ERROR :: Please run this script with ROOT access"
        exit 1
    fi

}
mkdir -p $LOGS_FOLDER

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling NodeJs 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing NodeJs"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "Adding expense user"
else
    echo -e "expense user existed already... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "downloading the code"

cd /app &>>$LOG_FILE_NAME
VALIDATE $? "Moving into app directory"
rm -rf /app/*

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping the code"

cd /app &>>$LOG_FILE_NAME
VALIDATE $? "moving to app directory"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing NPM"

cp /home/ec2-user/shell-expense/backend.service /etc/systemd/system/backend.service &>>$LOG_FILE_NAME

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Mysql"

mysql -h database.relationhospital.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "loading schema"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling Backend"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Restart backend"
