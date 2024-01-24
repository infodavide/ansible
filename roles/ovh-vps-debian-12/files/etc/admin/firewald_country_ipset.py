import os
import subprocess
import sys
import urllib
import wget

URL: str = 'https://www.ipdeny.com/ipblocks/data/countries/${code}.zone'
BLACKLIST_IPSET: str = 'blacklist_countries'
WHITELIST_IPSET: str = 'whitelist_countries'
INTERNAL_NET: str = '192.168.168.0/24'
TRUSTED_NET: str = ''
TRUSTED_ZONE: str = 'trusted'
FW_COMMAND: str = 'sudo firewall-cmd'


def add_entries(path: str, ipset: str):
    with open(path) as fp:
        for line in fp:
            values = line.split(';')
            code: str = values[1].strip()
            print('Downloading database for country: ' + code)
            try:
                filename = wget.download(URL.replace('${code}', code.lower()))
                print('Adding country IPs: ' + code + ' to IP set: ' + ipset)
                os.system(FW_COMMAND + ' --permanent --ipset=' + ipset + ' --add-entries-from-file=' + filename)
                os.unlink(filename)
            except urllib.error.HTTPError:
                sys.stderr.write('IPs of country ' + values[0] + ' are not available')


def download():
    print('Downloading databases...')
    add_entries("blacklist_countries.csv", BLACKLIST_IPSET)
    add_entries("whitelist_countries.csv", WHITELIST_IPSET)


if __name__ == '__main__':
    print('Collectiong existing IP sets...')
    result = subprocess.run(['sudo', 'firewall-cmd', '--permanent', '--get-ipsets'], stdout=subprocess.PIPE)
    ipsets = str(result.stdout)
    if BLACKLIST_IPSET in ipsets:
        print('Removing IP set: ' + BLACKLIST_IPSET)
        os.system(FW_COMMAND + ' --permanent --delete-ipset ' + BLACKLIST_IPSET)
    if WHITELIST_IPSET in ipsets:
        print('Removing IP set: ' + WHITELIST_IPSET)
        os.system(FW_COMMAND + ' --permanent --delete-ipset ' + WHITELIST_IPSET)
    os.system(FW_COMMAND + ' --reload')
    print('Creating IP set: ' + BLACKLIST_IPSET)
    os.system(FW_COMMAND + ' --permanent --new-ipset=' + BLACKLIST_IPSET + ' --type=hash:net --option=family=inet --option=hashsize=4096 --option=maxelem=200000')
    print('Creating IP set: ' + WHITELIST_IPSET)
    os.system(FW_COMMAND + ' --permanent --new-ipset=' + WHITELIST_IPSET + ' --type=hash:net --option=family=inet --option=hashsize=4096 --option=maxelem=200000')
    os.system(FW_COMMAND + ' --reload')
    download()
    if len(INTERNAL_NET) > 0:
        print('Adding ' + INTERNAL_NET + ' to internal zone')
        os.system(FW_COMMAND + ' --permanent --zone=internal --add-source=' + INTERNAL_NET)
    if len(TRUSTED_NET) > 0:
        print('Adding ' + TRUSTED_NET + ' to ' + TRUSTED_ZONE + ' zone')
        os.system(FW_COMMAND + ' --permanent --zone=' + TRUSTED_ZONE + ' --add-source=' + TRUSTED_NET)
    os.system(FW_COMMAND + ' --permanent --zone=drop --add-source=ipset:' + BLACKLIST_IPSET)
    os.system(FW_COMMAND + ' --permanent --zone=public --add-source=ipset:' + WHITELIST_IPSET)
    os.system(FW_COMMAND + ' --reload')
