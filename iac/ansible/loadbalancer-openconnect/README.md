# loadbalancer

ADD PRIVATE SSH KEY to GITHUB SECRETS

1. ssh to remote(target) server
2. ssh-keygen
3. cat ./ssh/id_rsa
4. create github secret with name PRIVATE
   paste public key there
   made empty line in the end
5. cat ./ssh/id_rsa.pub and paste to the ./ssh/authorized_keys on server


OPENCONNECT

add openconnect user to linux system or other, for login

 - adduser

test