#!/usr/bin/python3
import subprocess
import os
import sys

path = '%teamcity.build.checkoutDir%'
sfdx = 'sfdx'
alias = "cheeseburger"
auth_key = '%env.auth_key%'

def delete ():
    command="force:org:delete"
    delete = ['sfdx', command,
                '-u', alias,
                '-p']
    status = subprocess.call(delete, cwd=path)
    if status != 0:
        raise ValueError("Argument list %r failed with exit status %r" % (delete, status))
    elif status == 0:
        print("delete passed with exit code %r" % (status))

def auth():
    username="username@example.org"
    alias="Mercury"
    key="/root/server.key"
    command="force:auth:jwt:grant"
    auth= [ sfdx, command,
            '--clientid', auth_key,
            '--jwtkeyfile', key,
            '--username', username,
            '--setalias', alias,
            '--setdefaultdevhubusername']
    status = subprocess.call(auth, cwd=path)
    if status != 0:
        raise ValueError("Argument list %r failed with exit status %r" % (auth, status))
    elif status == 0:
        print("auth passed with exit code %r" % (status))
auth ()

def create():
    definitionfile="config/project-scratch-def.json"
    command="force:org:create"
    create = [sfdx, command,
            '-f', definitionfile,
            '--setdefaultusername',
            '-a', alias,
            '-d', str(1)]
    status = subprocess.call(create, cwd=path)
    if status != 0:
        raise ValueError("Argument list %r failed with exit status %r" % (create, status))
    elif status == 0:
        print("create passed with exit code %r" % (status))
create ()

def push():
    command="force:source:push"
    push = [ sfdx, command]
    status = subprocess.call(push, cwd=path)
    if status != 0:
        delete()
        raise ValueError("Argument list %r failed with exit status %r" % (push, status))
    elif status == 0:
        print("push passed with exit code %r" % (status))
push ()

def permset():
    command="force:user:permset:assign"
    user="sfdx_user"
    permset = [sfdx, command,
            '-n', user]
    status = subprocess.call(permset, cwd=path)
    if status != 0:
        delete()
        raise ValueError("Argument list %r failed with exit status %r" % (permset, status))
    elif status == 0:
        print("permset passed with exit code %r" % (status))
permset ()

def apex_tests():
    command="force:apex:test:run"
    formatting="human"
    loglevel="error"
    apex_tests = ['sfdx', command,
            '--resultformat', formatting,
            '--loglevel', loglevel]
    status = subprocess.call(apex_tests, cwd=path)
    if status != 0:
        delete()
        raise ValueError("Argument list %r failed with exit status %r" % (apex_tests, status))
    elif status == 0:
        print("apex_tests passed with exit code %r" % (status))
apex_tests ()
delete ()

### literal commands in shell

#auth = sfdx force:auth:jwt:grant --clientid insertclientid --jwtkeyfile /root/server.key --username username@example.org --setalias Mercury --setdefaultdevhubusername
#create = sfdx force:org:create -f config/project-scratch-def.json --setdefaultusername -a cheeseburger
#push = sfdx force:source:push
#force = sfdx force:user:permset:assign -n sfdx_user
#apex = sfdx force:apex:test:run --resultformat human --loglevel error
#delete = sfdx force:org:delete -u cheeseburger -p


#os.chdir(path)
#os.system(auth)
#os.system(create)
#os.system(push)
#os.system(force)
#os.system(apex)
#os.system(delete)
