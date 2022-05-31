cat << EOF | tee /etc/ssmtp/ssmtp.conf
UseSTARTTLS=YES
FromLineOverride=YES
root=$PARAM_FROM
mailhub=$SMTP_HOST:587
AuthUser=$SMTP_USER
AuthPass=$SMTP_PASS
EOF

cat << EOF | tee /etc/ssmtp/revaliases
root:$PARAM_FROM:$SMTP_HOST:587
circleci:$PARAM_FROM:$SMTP_HOST:587
EOF

cat > mail.txt << EOF
To: $PARAM_TO
From: $PARAM_FROM
Subject: $PARAM_SUBJECT
MIME-Version: 1.0
Content-Type: text/html; charset=utf-8

EOF


cat $PARAM_BODY_FILE >> mail.txt

ssmtp $PARAM_TO < mail.txt