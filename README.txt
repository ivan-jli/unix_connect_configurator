ArchLinux OpenSSH documentation:

Troubleshooting
Checklist

Check these simple issues before you look any further.

    The configuration directory ~/.ssh, its contents should be accessible only by the user (check this on both the client and the server), and the user's home folder should only be writable by the user:

    $ chmod go-w ~
    $ chmod 700 ~/.ssh
    $ chmod 600 ~/.ssh/*
    $ chown -R $USER ~/.ssh

    Check that the client's public key (e.g. id_rsa.pub) is in ~/.ssh/authorized_keys on the server.
    Check that you did not limit SSH access with AllowUsers or AllowGroups in the server config.
    Check if the user has set a password. Sometimes new users who have not yet logged in to the server do not have a password.
    Append LogLevel DEBUG to /etc/ssh/sshd_config.
    Run journalctl -xe as root for possible (error) messages.
    Restart sshd and logout/login on both client and server.

TODO: fix the points above in the configServer.sh


