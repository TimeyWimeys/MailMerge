# MailMerge
 A free to use mail web panel supporting postfix,dovecot,clamav & spamassassin.

Currently only supporting debuntu (Debian & Ubuntu)

## About
This is a personal project not used for production workplaces (yet).

Making this due to the lacking function of cloudpanel that only has functionality for databases, domain-management and ftp/sftp/ssh features.

This is an optional program to compliment cloudpanel. I'm a total beginner to coding, so expect a lot of bugs.

1. Login as root.
    ```
    sudo su -
    ```

2. Install GIT

    ```
    apt-get install -y git
    ```

3. Download Mailmerge using git to the `/opt/mailmerge` directory
    ```
    cd /opt
    git clone https://github.com/TimeyWimeys/mailmerge.git
    cd mailmerge
    chmod +x /opt/mailmerge/install.sh
   ./install.sh
    ```